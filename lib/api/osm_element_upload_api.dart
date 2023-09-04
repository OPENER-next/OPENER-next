import 'package:flutter/foundation.dart';
import 'package:osm_api/osm_api.dart';

import '/models/changeset_comment_builder.dart';
import '/models/element_processing/element_processor.dart';
import '/models/element_variants/base_element.dart';
import '/models/authenticated_user.dart';
import '/commons/app_config.dart' as app_config;
import '/commons/osm_config.dart' as osm_config;
import '/models/stop_area_processing/stop_area.dart';


// NOTE:
// A potential problem for finding related changeset is that the generated
// changeset bbox can be larger then the stop area bbox,
// because the stop area bbox doesn't take the dimensions of ways into account.


class OSMElementUploadAPI {
  final StopArea stopArea;

  AuthenticatedUser _authenticatedUser;

  String changesetCreatedBy;

  String changesetSource;

  String changesetLocale;

  final OSMAPI _osmApi;

  OSMElementUploadAPI({
    required this.stopArea,
    required AuthenticatedUser authenticatedUser,
    String endPoint = 'https://${osm_config.osmServer}/api/0.6',
    this.changesetCreatedBy = '${app_config.appName} ${app_config.appVersion}',
    this.changesetSource = 'survey',
    this.changesetLocale = 'de'
  }) :
    _authenticatedUser = authenticatedUser,
    _osmApi = OSMAPI(
      authentication: authenticatedUser.authentication,
      baseUrl: endPoint,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    );


  set authenticatedUser(AuthenticatedUser value) {
    _authenticatedUser = value;
    _osmApi.authentication = _authenticatedUser.authentication;
  }

  AuthenticatedUser get authenticatedUser => _authenticatedUser;


  /// Upload the given element to the OSM server.
  ///
  /// The given [ProcessedElement] must be created from the given [OSMElement]
  /// or in other words encapsulate the original element.
  ///
  /// This updates the element version on success.

  Future<OSMElement> updateOsmElement(ProcessedElement processedElement, OSMElement originalElement) async {
    final changesetId = await _createOrReuseChangeset(stopArea, processedElement);
    return _osmApi.updateElement(originalElement, changesetId);
  }


  /// Creates or retrieves (and updates) a suitable changeset for the given element and returns its id.

  Future<int> _createOrReuseChangeset(StopArea stopArea, ProcessedElement newElement) async {
    final changesetData = {
      'created_by': changesetCreatedBy,
      'source': changesetSource,
      'locale': changesetLocale,
    };
    var changesetId = await _getReusableChangesetId(stopArea);

    // update existing changeset tags
    if (changesetId != null) {
      // gather all previously modified elements of this changeset
      final changesetElements = await _getChangesetElements(changesetId);
      final changesetCommentBuilder = ChangesetCommentBuilder(
        modifiedElements: [newElement, ...changesetElements],
        stopArea: stopArea,
      );
      changesetData['comment'] = changesetCommentBuilder.toString();
      await _osmApi.updateChangeset(changesetId, changesetData);
    }
    // create new changeset
    else {
      final changesetCommentBuilder = ChangesetCommentBuilder(
        modifiedElements: [newElement],
        stopArea: stopArea,
      );
      changesetData['comment'] = changesetCommentBuilder.toString();
      changesetId = await _osmApi.createChangeset(changesetData);
    }

    return changesetId;
  }


  /// Get any open changeset that was created by our app and is inside the current stop area.

  Future<int?> _getReusableChangesetId(StopArea stopArea) async {
    final bbox = stopArea.bounds;
    // get existing open changesets that was created by the user
    final changesets = await _osmApi.queryChangesets(
      open: true,
      uid: _authenticatedUser.id,
      bbox: BoundingBox(bbox.west, bbox.south, bbox.east, bbox.north)
    );

    try {
      return changesets.firstWhere((changeset) {
        return changeset.tags['created_by'] == changesetCreatedBy;
      }).id;
    }
    on StateError {
      return null;
    }
  }


  /// Queries all elements that were modified in the given changeset.
  ///
  /// This will also retrieve any (none modified) child elements for ways and
  /// relations which is required to create complete [ProcessedElement]s.
  /// However only the elements modified by the given changeset will be returned.

  Future<Iterable<ProcessedElement>> _getChangesetElements(int changesetId) async {
    // gather all modified elements of this changeset
    final changes = await _osmApi.getChangesetChanges(changesetId);
    final changesWithChildren = await _queryFullElements(changes.modify);
    // create processed elements for all modified elements + children
    final elementProcessor = OSMElementProcessor(changesWithChildren);
    // filter processed elements to only contain the original modified elements
    // otherwise we might match elements to map features that weren't modified
    // but are children of a modified element
    return elementProcessor.elements.where((pElement) {
      return changes.modify.elements.any(
        (oElement) => pElement.isOriginal(oElement),
      );
    });
  }


  /// This will query all child elements from ways and relations in the given bundle.
  /// The returned bundle will contain all elements from the given bundle plus any child elements.

  Future<OSMElementBundle> _queryFullElements(OSMElementBundle bundle) async {
    // create new bundle with only the nodes of the original bundle
    // the ways and relations with all their children will be queried and added (if successful) to this bundle
    final newBundle = OSMElementBundle(nodes: bundle.nodes);

    // re-query ways and relations with child elements
    final requestQueue = [
      for (final way in bundle.ways) _osmApi.getFullWay(way.id),
      for (final relation in bundle.relations) _osmApi.getFullRelation(relation.id),
    ];

    // wait till all requests are resolved
    // handle them in a stream in order to catch individual errors
    await Stream.fromFutures(requestQueue)
      .handleError((e) {
        // catch any errors and ignore these elements
        // for example the element or its children might be deleted by now
        debugPrint('Could not query element of existing changeset: $e');
      })
      .forEach(newBundle.merge);

    return newBundle;
  }


  /// A method to terminate the api client and cleanup any open connections.
  /// This should be called inside the widgets dispose callback.

  void dispose() {
    _osmApi.dispose();
  }
}
