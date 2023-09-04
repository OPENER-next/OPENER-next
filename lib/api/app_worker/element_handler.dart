import 'dart:async';

import 'package:flutter_map/flutter_map.dart';
import 'package:osm_api/osm_api.dart' as osmapi;

import '/models/map_features/map_features.dart';
import '/models/map_features/map_feature_representation.dart';
import '/models/question_catalog/question_catalog_reader.dart';
import '/models/affected_elements_detector.dart';
import '/models/element_variants/element_identifier.dart';
import '/api/osm_element_query_api.dart';
import '/api/osm_element_upload_api.dart';
import '/api/app_worker/questionnaire_handler.dart';
import '/models/element_processing/element_filter.dart';
import '/models/element_processing/element_processor.dart';
import '/models/element_variants/base_element.dart';
import '/models/geographic_geometries.dart';
import '/models/stop_area_processing/stop_area.dart';
import '/utils/stream_utils.dart';
import '/utils/service_worker.dart';
import 'question_catalog_handler.dart';
import 'stop_area_handler.dart';

/// Allows querying stop area elements.
///
/// All downloaded elements are cached in the [OSMElementProcessor].

mixin ElementHandler<M> on ServiceWorker<M>, StopAreaHandler<M>, QuestionCatalogHandler<M> {
  final _elementStreamController = StreamController<ElementUpdate>();

  /// A MultiStream that returns any existing elements on initial subscription.
  ///
  /// Note for overlapping stop areas this may return the same element twice
  ///
  /// While the underlying code knows if an element was already downloaded,
  /// it doesn't know whether it already passed a stop area filter (was visible to the user).
  ///
  /// Moving the filters inside the element processing step and removing
  /// non matching elements there is not a good idea, due to child/parent reference problems.

  late final elementStream = _elementStreamController.stream.makeMultiStreamAsync((controller) async {
    final existingElements = _filterElements(
      _buildFiltersForStopAreas(loadedStopAreas),
      Stream.fromIterable(_elementPool.elements),
    );
    final elementUpdates = existingElements.map((element) => ElementUpdate.derive(
      element, action: ElementUpdateAction.update,
    ));
    return controller.addStream(elementUpdates);
  });

  final _elementPool = OSMElementProcessor();

  final _osmElementQueryHandler = OSMElementQueryAPI();

  @override
  void updateQuestionCatalog(QuestionCatalogChange questionCatalogChange) async {
    super.updateQuestionCatalog(questionCatalogChange);
    final existingElements = _filterElements(
      _buildFiltersForStopAreas(loadedStopAreas),
      Stream.fromIterable(_elementPool.elements),
    );
    _elementStreamController.add(const ElementUpdate(action: ElementUpdateAction.clear));
    existingElements
      .map((element) => ElementUpdate.derive(element, action: ElementUpdateAction.update))
      .forEach(_elementStreamController.add);
  }

  /// Retrieves all stop areas in the given bounds and queries the elements for any unloaded stop area.
  ///
  /// New elements will be added to the [elementStream].

  Future<void> queryElements(LatLngBounds bounds) async {
    final closeStopAreas = getStopAreasByBounds(bounds);
    final futures = <Future<void>>[];

    for (final stopArea in closeStopAreas) {
      final elements = _queryElementsByStopArea(stopArea);
      // filter elements
      final filteredElements = _filterElements(
        _buildFiltersForStopArea(stopArea), elements,
      );
      // construct element updates
      final elementUpdates = filteredElements.map((element) => ElementUpdate.derive(
        element, action: ElementUpdateAction.update,
      ));
      // add newly queried elements to stream
      futures.add(
        elementUpdates.forEach(_elementStreamController.add),
      );
    }
    // used to only complete this function once all queries and processing is completed
    // and also to forward any errors (especially query errors)
    await Future.wait(futures, eagerError: true);
  }

  Stream<ProcessedElement> _queryElementsByStopArea(StopArea stopArea) async* {
    if (stopAreaIsUnloaded(stopArea)) {
      // add to current loading stop areas and mark as loading
      markStopArea(stopArea, StopAreaState.loading);
      try {
        // query elements by stop areas bbox
        final elementBundle = await _osmElementQueryHandler.queryByBBox(stopArea.bounds);
        // process stop area elements
        final stopAreaElements = _elementPool
          .add(elementBundle)
          .map((record) => record.element);
        // on success add to loaded stop areas and mark accordingly
        if (await stopAreaHasQuestions(stopArea, stopAreaElements)) {
          markStopArea(stopArea, StopAreaState.incomplete);
        }
        else {
          markStopArea(stopArea, StopAreaState.complete);
        }
        // return new elements
        yield* Stream.fromIterable(stopAreaElements);
      }
      catch(e) {
        markStopArea(stopArea, StopAreaState.unloaded);
        rethrow;
      }
    }
  }

  /// Quickly find a downloaded element by its identifier.

  ProcessedElement<osmapi.OSMElement, GeographicGeometry>? findElement(ElementIdentifier elementIdentifier) {
    return _elementPool.find(elementIdentifier.type, elementIdentifier.id);
  }


  /// Uploads a given element.
  /// Sends update events for the given element and its dependents.
  ///
  /// Returns true if upload was successful, otherwise false.

  Future<bool> uploadElement(ProxyElement element, ElementUploadData uploadData) async {
    final qCatalog = await questionCatalog;

    final stopArea = findCorrespondingStopArea(element);

    // upload with first StopArea occurrence
    final uploadAPI = OSMElementUploadAPI(
      stopArea: stopArea,
      authenticatedUser: uploadData.user,
      changesetLocale: uploadData.locale.languageCode,
    );

    try {
      // upload element and detect elements that are affected by this change
      final diffDetector = AffectedElementsDetector(questionCatalog: qCatalog);
      diffDetector.takeSnapshot(element.original);
      await element.publish(uploadAPI);
      final affectedElements = diffDetector.takeSnapshot(element.original);

      // update stop area state
      if (await stopAreaHasQuestions(stopArea, _elementPool.elements)) {
        markStopArea(stopArea, StopAreaState.incomplete);
      }
      else {
        markStopArea(stopArea, StopAreaState.complete);
      }

      affectedElements
        // add the element itself to the affected elements
        .followedBy([AffectedElementsRecord(
          element: element.original,
          matches: QuestionFilter(questionCatalog: qCatalog).matches(element),
        )])
        // send update messages to the main thread
        .map((record) => ElementUpdate.derive(
          record.element,
          action: record.matches
            ? ElementUpdateAction.update
            : ElementUpdateAction.remove,
        ))
        .forEach(_elementStreamController.add);

      return true;
    }
    catch(e) {
      return false;
    }
    // this is always executed, before the returns
    finally {
      uploadAPI.dispose();
    }
  }

  @override
  Future<bool> stopAreaHasQuestions(StopArea stopArea, [Iterable<ProcessedElement>? elements]) async {
    final filteredElements = _filterElements(
      _buildFiltersForStopArea(stopArea),
      Stream.fromIterable(elements ?? _elementPool.elements),
    );
    return !(await filteredElements.isEmpty);
  }

  Stream<ProcessedElement> _filterElements(Stream<ElementFilter> filters, Stream<ProcessedElement> elements) async* {
    yield* await filters.fold<Stream<ProcessedElement>>(
      elements,
      (elements, filter) => filter.asyncFilter(elements),
    );
  }

  Stream<ElementFilter> _buildFiltersForStopArea(StopArea stopArea) async* {
    yield QuestionFilter(questionCatalog: await questionCatalog);
    yield AreaFilter(area: stopArea);
  }

  Stream<ElementFilter> _buildFiltersForStopAreas(Iterable<StopArea> stopAreas) async* {
    yield QuestionFilter(questionCatalog: await questionCatalog);
    yield AnyFilter(filters: stopAreas.map((s) => AreaFilter(area: s)));
  }

  @override
  void exit() {
    _osmElementQueryHandler.dispose();
    _elementStreamController.close();
    super.exit();
  }
}


enum ElementUpdateAction { update, remove, clear }

class ElementUpdate {
  final MapFeatureRepresentation? element;
  final ElementUpdateAction action;

  const ElementUpdate({
    required this.action, this.element,
  });

  ElementUpdate.derive(ProcessedElement element, {required this.action}) :
    element = MapFeatures.representElement(element);
}
