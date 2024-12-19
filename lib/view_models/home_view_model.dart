import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart' hide Action, ProxyElement, Notification;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_mvvm_architecture/base.dart';
import 'package:flutter_mvvm_architecture/extras.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobx/mobx.dart';
import 'package:osm_api/osm_api.dart';
import 'package:animated_location_indicator/animated_location_indicator.dart';
import '/api/app_worker/element_handler.dart';
import '/models/map_features/map_feature_representation.dart';
import '/models/question_catalog/question_definition.dart';
import '/models/questionnaire.dart';
import '/models/stop_area/stop_area.dart';
import '/utils/debouncer.dart';
import '/widgets/question_inputs/question_input_widget.dart';
import '/api/user_account_service.dart';
import '/api/preferences_service.dart';
import '/utils/geo_utils.dart';
import '/utils/map_utils.dart';
import '/api/app_worker/app_worker_interface.dart';
import '/api/app_worker/stop_area_handler.dart';


class HomeViewModel extends ViewModel with MakeTickerProvider, PromptMediator, NotificationMediator {

  final questionDialogMaxHeightFactor = 2/3;

  AppWorkerInterface get _appWorker => getService<AppWorkerInterface>();

  PreferencesService get _preferencesService => getService<PreferencesService>();

  final _userAccountService = UserAccountService();

  final _reactionDisposers = <ReactionDisposer>[];

  HomeViewModel() {
    _reactionDisposers.add(
      reaction((p0) => _mapEventStream.value, _onMapEvent),
    );

    _reactionDisposers.add(
      reaction((p0) => _mapEventStream.value, _onDebouncedMapEvent, delay: 1000),
    );

    _stopAreaSubscription = _appWorker.subscribeStopAreas().listen(_markStopArea);

    // request location permissions and service on startup
    _requestLocationPermission().then((granted) {
      if (granted) locationIndicatorController.activate();
    });
  }

  @override
  void init() {
    super.init();
    final appLocale = AppLocalizations.of(context)!;
    // one time reaction when the first stop areas are available,
    // then try to load its elements
    _reactionDisposers.add(when(
      (p0) => _unloadedStopAreas.isNotEmpty,
      _onDebouncedMapEvent,
    ));

    promptUserInput(Prompt(
      title: appLocale.deprecationPromptTitle,
      message: appLocale.deprecationPromptMessage,
      choices: { 'Okay': null },
    ));
  }

  ////////////////////////////
  /// Stop Area properties ///
  ////////////////////////////

  final _unloadedStopAreas = ObservableSet<StopArea>();
  final _loadingStopAreas = ObservableSet<StopArea>();
  final _completeStopAreas = ObservableSet<StopArea>();
  final _incompleteStopAreas = ObservableSet<StopArea>();

  late final unloadedStopAreas = UnmodifiableSetView(_unloadedStopAreas);
  late final loadingStopAreas = UnmodifiableSetView(_loadingStopAreas);
  late final completeStopAreas = UnmodifiableSetView(_completeStopAreas);
  late final incompleteStopAreas = UnmodifiableSetView(_incompleteStopAreas);

  void _markStopArea(StopAreaUpdate change) {
    final stopArea = change.stopArea;
    switch (change.state) {
      case StopAreaState.unloaded:
        _loadingStopAreas.remove(stopArea) || _incompleteStopAreas.remove(stopArea) || _completeStopAreas.remove(stopArea);
        _unloadedStopAreas.add(stopArea);
      break;
      case StopAreaState.loading:
        _unloadedStopAreas.remove(stopArea) || _incompleteStopAreas.remove(stopArea) || _completeStopAreas.remove(stopArea);
        _loadingStopAreas.add(stopArea);
      break;
      case StopAreaState.complete:
        _unloadedStopAreas.remove(stopArea) || _loadingStopAreas.remove(stopArea) || _incompleteStopAreas.remove(stopArea);
        _completeStopAreas.add(stopArea);
      break;
      case StopAreaState.incomplete:
        _unloadedStopAreas.remove(stopArea) || _loadingStopAreas.remove(stopArea) || _completeStopAreas.remove(stopArea);
        _incompleteStopAreas.add(stopArea);
      break;
    }
  }

  late final StreamSubscription<StopAreaUpdate> _stopAreaSubscription;

  late final _loadingChunks = ObservableStream(_appWorker.subscribeLoadingChunks(), initialValue: 0);

  late final _isLoadingStopAreas = Computed(() => (_loadingChunks.value ?? 0) > 0);

  /// Whether there are any open/ongoing requests.

  bool get isLoadingStopAreas => _isLoadingStopAreas.value;

  /// This should be called on camera position changes and will trigger a database query if necessary.
  /// The query results can be accessed via the specific "stop areas" property.

  void loadStopAreas() async {
    if (mapController.camera.zoom > 11) {
      _appWorker.queryStopAreas(mapController.camera.visibleBounds);
    }
  }

  ////////////////////////////////
  /// User Location properties ///
  ////////////////////////////////

  late final locationIndicatorController = AnimatedLocationController(vsync: this);

  final _cameraIsFollowingLocation = Observable<bool>(false);
  bool get cameraIsFollowingLocation => _cameraIsFollowingLocation.value;

  /// Activate or deactivate location following depending on its current state.

  void toggleLocationFollowing() async {
    if (!(await _requestLocationPermission())) {
      return runInAction(() {
        _cameraIsFollowingLocation.value = false;
      });
    }
    else if (cameraIsFollowingLocation == false) {
      if (!locationIndicatorController.isActive) {
        locationIndicatorController.activate();
      }
      try {
        await mapController.animateTo(
          ticker: this,
          location: await _incomingLocation,
          id: 'KeepCameraTracking',
        ).orCancel;
      }
      on TickerCanceled {
        return;
      }
    }
    runInAction(() {
      _cameraIsFollowingLocation.value = !cameraIsFollowingLocation;
    });
  }

  // if no location permission was granted the initial location is unset, so we need to wait for it
  Future<LatLng> get _incomingLocation async {
    if (locationIndicatorController.location == null) {
      final completer = Completer<LatLng>();
      void complete() {
        if (locationIndicatorController.location != null) {
          locationIndicatorController.removeListener(complete);
          completer.complete(locationIndicatorController.location);
        }
      }
      locationIndicatorController.addListener(complete);
      return completer.future;
    }
    return locationIndicatorController.location!;
  }

  Future<bool> _requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always ||
           permission == LocationPermission.whileInUse;
  }

  //////////////////////////////
  /// Preferences properties ///
  //////////////////////////////

  LatLng get storedMapLocation => _preferencesService.mapLocation;
  double get storedMapRotation => _preferencesService.mapRotation;
  double get storedMapZoom => _preferencesService.mapZoom;

  //////////////////////
  /// Map properties ///
  //////////////////////

  // WARNING: Accessing this before the map widget is instantiated will cause "late" initialization errors.
  // This might especially occur for the getters below.
  final mapController = MapController();

  late final _mapEventStream = ObservableStream(mapController.mapEventStream);

  late final _mapRotation = Computed(() {
    _mapEventStream.value; // used to subscribe to changes
    return mapController.camera.rotation;
  });
  double get mapRotation => _mapRotation.value;

  late final _mapZoom = Computed(() {
    _mapEventStream.value; // used to subscribe to changes
    return mapController.camera.zoom;
  });
  double get mapZoom => _mapZoom.value;

  late final _mapZoomRound = Computed(() {
    final decimalPart = mapZoom - mapZoom.truncate();
    return decimalPart > 0.9 ? mapZoom.ceil() : mapZoom.floor();
  });
  /// Special rounding function, which mostly floors the value except for numbers very close to the next integer.
  ///
  /// Mainly used to hide markers early when zooming out.
  int get mapZoomRound => _mapZoomRound.value;

  late final _mapPosition = Computed(() {
    _mapEventStream.value; // used to subscribe to changes
    return mapController.camera.center;
  });
  LatLng get mapPosition => _mapPosition.value;

  /// Zoom the map view.

  void zoomIn() {
    // round zoom level so zoom will always stick to integer levels
    mapController.animateTo(
      ticker: this,
      zoom: mapController.camera.zoom.roundToDouble() + 1,
    );
  }

  /// Zoom out of the map view.

  void zoomOut() {
    // round zoom level so zoom will always stick to integer levels
    mapController.animateTo(
      ticker: this,
      zoom: mapController.camera.zoom.roundToDouble() - 1,
    );
  }

  /// Reset the map rotation.

  void resetRotation() {
    mapController.animateTo(ticker: this, rotation: 0);
  }

  ///////////////////////////////
  /// User Account properties ///
  ///////////////////////////////

  bool get userIsLoggedIn => _userAccountService.isLoggedIn;

  String? get userName => _userAccountService.authenticatedUser?.name;

  String? get userProfileImageUrl => _userAccountService.authenticatedUser?.profileImageUrl;

  void login() => _userAccountService.login();

  void logout() async {
    final appLocale = AppLocalizations.of(context)!;
    final choice = await promptUserInput(Prompt(
      title: appLocale.logoutDialogTitle,
      message: appLocale.logoutDialogDescription,
      choices: {
        appLocale.logout: true,
        appLocale.cancel: false,
      },
      isDismissible: true,
    ));

    if (choice == true) {
      _userAccountService.logout();
    }
  }

  void openUserProfile() => _userAccountService.openUserProfile();

  ////////////////////////////////
  /// Questionnaire properties ///
  ////////////////////////////////

  late final _questionnaireState = ObservableStream(_appWorker.subscribeQuestionnaireChanges());

  late final _hasQuestionnaire = Computed(() => _questionnaireState.value != null);
  bool get hasQuestionnaire => _hasQuestionnaire.value;

  late final _questionCount = Computed(() => _questionnaireState.value?.entries.length ?? 0);
  int get questionCount => _questionCount.value;

  late final _currentQuestionnaireIndex = Computed(() => _questionnaireState.value?.activeIndex);
  int? get currentQuestionnaireIndex => _currentQuestionnaireIndex.value;

  late final _questionnaireIsFinished = Computed(() => _questionnaireState.value?.isCompleted == true);
  /// Whether all questions of the current questionnaire have been visited.
  bool get questionnaireIsFinished => _questionnaireIsFinished.value;

  // used to throttle input changes

  final _answerInputDebouncer = Debouncer(const Duration(milliseconds: 500));

  UnmodifiableListView<QuestionDefinition> get questionnaireQuestions {
    return UnmodifiableListView(
      _questionnaireState.value?.entries.map(
        (entry) => entry.question,
      ) ?? const Iterable.empty(),
    );
  }

  /// Never use this directly. Instead use [questionnaireAnswers].
  ///
  /// Holds any AnswerControllers with their corresponding QuestionnaireEntry

  final _answerControllerMapping = <QuestionnaireEntry, AnswerController>{};

  UnmodifiableListView<AnswerController> get questionnaireAnswers {
    // ensure every question entry has a corresponding controller
    _updateAnswerControllers();

    return UnmodifiableListView<AnswerController>(
      _questionnaireState.value?.entries.map(
        (entry) => _answerControllerMapping[entry]!,
      ) ?? const Iterable.empty(),
    );
  }

  /// This either reopens an existing questionnaire or creates a new one.

  void _openQuestionnaire(MapFeatureRepresentation element) {
    if (_questionnaireState.value != null) {
      // store latest answer from previous questionnaire
      _updateQuestionnaireAnswer();
    }
    // if a previous questionnaire existed, remove all corresponding answer controllers
    // this is necessary since the QuestionnaireEntry -> AnswerController mapping is only unique per questionnaire
    // other questionnaires might have the exact same QuestionnaireEntry and would therefore otherwise reuse previous AnswerControllers
    _updateAnswerControllers(forceCleanUp: true);

    _appWorker.openQuestionnaire(element);
    runInAction(() => _selectedElement.value = element);
  }

  /// Close the currently active questionnaire if any.

  void closeQuestionnaire() {
    if (_questionnaireState.value != null) {
      // store latest answer from questionnaire
      _updateQuestionnaireAnswer();
      _appWorker.closeQuestionnaire();
      // deselect element
      runInAction(() => _selectedElement.value = null);
    }
  }

  /// Upload the changes made by this questionnaire with the current authenticated user.

  void submitQuestionnaire() async {
    final appLocale = AppLocalizations.of(context)!;
    final alteredElement = selectedElement;

    if (_userAccountService.isLoggedOut) {
      // wait till the user login process finishes
      await _userAccountService.login();
    }
    // check if the user is successfully logged in
    // check if mounted to ensure context is valid
    if (_userAccountService.isLoggedIn && mounted) {
      try {
        // deselect element
        runInAction(() => _selectedElement.value = null);
        // this automatically closes the questionaire
        final uploading = _appWorker.uploadQuestionnaire(
          user: _userAccountService.authenticatedUser!,
        );
        _uploadQueue[alteredElement!] = uploading;
        await uploading;
      }
      on OSMConnectionException {
        notifyUser(Notification(appLocale.uploadMessageServerConnectionError));
      }
      catch(e) {
        debugPrint(e.toString());
        notifyUser(Notification(appLocale.uploadMessageUnknownConnectionError));
      }
      finally {
        _uploadQueue.remove(alteredElement);
      }
    }
  }

  void goToPreviousQuestion() {
    // always unfocus the current node to close all onscreen keyboards
    FocusManager.instance.primaryFocus?.unfocus();
    _updateQuestionnaireAnswer();
    _appWorker.previousQuestion();
  }

  void goToNextQuestion() {
    // always unfocus the current node to close all onscreen keyboards
    FocusManager.instance.primaryFocus?.unfocus();
    _updateQuestionnaireAnswer();
    _appWorker.nextQuestion();
  }

  void jumpToQuestion(int index) {
    // always unfocus the current node to close all onscreen keyboards
    FocusManager.instance.primaryFocus?.unfocus();
    _updateQuestionnaireAnswer();
    _appWorker.jumpToQuestion(index);
  }

  /// Updates the questionnaire with the current answer.
  /// This refreshes the questionnaire and may add new or remove obsolete questions.

  Future<void> _updateQuestionnaireAnswer() async {
    if (_questionnaireState.value != null) {
      // cancel any queued callbacks
      _answerInputDebouncer.cancel();
      final index = _questionnaireState.value!.activeIndex;
      final answerController = questionnaireAnswers[index];
      return _appWorker.updateQuestionnaire(answerController.answer);
    }
  }

  /// Maps all [QuestionnaireEntry]s to typed [AnswerController]s.
  /// Should be called on every questionnaire "update".
  /// If no questionnaire is selected this will remove and dispose all left over answer controllers.

  void _updateAnswerControllers({ bool forceCleanUp = false }) {
    final questionEntries = forceCleanUp || _questionnaireState.value == null
      ? const <QuestionnaireEntry>[]
      : _questionnaireState.value!.entries;

    // remove obsolete answer controllers
    _answerControllerMapping.removeWhere((questionEntry, controller) {
      if (!questionEntries.contains(questionEntry)) {
        controller.dispose();
        return true;
      }
      return false;
    });
    // add new answer controllers for each entry if none already exists
    for (final questionEntry in questionEntries) {
      _answerControllerMapping.putIfAbsent(
        questionEntry,
        () => AnswerController.fromType(
          type: questionEntry.question.answer.runtimeType,
          initialAnswer: questionEntry.answer,
          // Calling this repeatedly might be expensive, since a questionnaire update
          // will go through all questions and check whether they still match or start
          // matching.
          // The questionnaire is still updated on "go to next/previous question" calls.
        )..addListener(_answerInputDebouncer.debounce(_updateQuestionnaireAnswer))
      );
    }
  }

  //////////////////////////
  /// Element properties ///
  //////////////////////////

  // make it public so add, removal and update can be observed

  late final StreamView<ElementUpdate> elements = StreamView(_appWorker.subscribeElements());

  /// Load and extract elements from a given stop area and question catalog.

  Future<void> loadElements() async {
    if (mapController.camera.zoom >= 16) {
      // query elements
      return _appWorker.queryElements(mapController.camera.visibleBounds);
    }
  }

  final _uploadQueue = ObservableMap<MapFeatureRepresentation, Future>();
  late final uploadQueue = UnmodifiableMapView(_uploadQueue);

  final _selectedElement = Observable<MapFeatureRepresentation?>(null);
  MapFeatureRepresentation? get selectedElement => _selectedElement.value;

  late final _hasSelectedElement = Computed(() => selectedElement != null);
  bool get hasSelectedElement => _hasSelectedElement.value;

  /// An unique identifier for the currently selected element.
  late final _selectedElementKey = Computed(() {
    // generate unique key every time the selected element identifier changes
    selectedElement;
    return UniqueKey();
  });
  Key get selectedElementKey => _selectedElementKey.value;

  void onElementTap(MapFeatureRepresentation element) {
    // show questions if a new marker is selected, else hide the current one
    if (_selectedElement.value != element) {
      _openQuestionnaire(element);
    }
    else {
      return closeQuestionnaire();
    }

    final mediaQuery = MediaQuery.of(context);

    // Build bounding box which is mirrored at the center point and extend the normal bbox by it.
    // This adjusts the bbox so that the geometry center point is in the middle of the viewed bounding box
    // while it ensures that the geometry is visible (within in the bounding box).
    final bounds = element.geometry.bounds;
    bounds.extendBounds(bounds.mirror(
      element.geometry.center,
    ));

    // move camera to element and include default sheet size as bottom padding
    mapController.animateToBounds(
      ticker: this,
      bounds: bounds,
      // calculate padding based on question dialog max height
      padding: EdgeInsets.only(
        top: mediaQuery.padding.top,
        bottom: mediaQuery.size.height * questionDialogMaxHeightFactor
      ),
      // only zoom in to fit the object, but never zoom out
      minZoom: mapController.camera.zoom,
      // zoom in on 20 or more if the current zoom level is above 20
      // required due to clustering, because not all markers may be visible on zoom level 20
      maxZoom: max(20, mapController.camera.zoom)
    );
  }


  void _onMapEvent(MapEvent? event) {
    // cancel tracking on user interaction or any map move not caused by the camera tracker
    if (!(event is MapEventRotate || event is MapEventMove && (
          event.id == 'KeepCameraTracking' ||
          event.id == 'AnimatedLocationLayerCameraTracking' ||
          event.camera.center == event.oldCamera.center
    ))) {
      runInAction(() => _cameraIsFollowingLocation.value = false);
    }
  }


  void _onDebouncedMapEvent([MapEvent? event]) async {
     final appLocale = AppLocalizations.of(context)!;

    // store map location on map move events
    _preferencesService
      ..mapLocation = mapController.camera.center
      ..mapZoom = mapController.camera.zoom
      ..mapRotation = mapController.camera.rotation;

    // query stop areas on map interactions
    loadStopAreas();

    try {
      // query elements from loaded stop areas
      await loadElements();
    }
    on OSMUnknownException catch (e) {
      if (e.errorCode == 503) {
        debugPrint(e.toString());
        notifyUser(Notification(appLocale.queryMessageServerUnavailableError));
      }
      else if (e.errorCode == 429) {
        debugPrint(e.toString());
        notifyUser(Notification(appLocale.queryMessageTooManyRequestsError));
      }
      else {
        rethrow;
      }
    }
    on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        notifyUser(Notification(appLocale.queryMessageConnectionTimeoutError));
      }
      else if (e.type == DioExceptionType.receiveTimeout) {
        notifyUser(Notification(appLocale.queryMessageReceiveTimeoutError));
      }
      else {
        debugPrint(e.toString());
        notifyUser(Notification(appLocale.queryMessageUnknownServerCommunicationError));
      }
    }
    catch(e) {
      debugPrint(e.toString());
      notifyUser(Notification(appLocale.queryMessageUnknownError));
    }
  }


  @override
  void dispose() {
    _stopAreaSubscription.cancel();

    locationIndicatorController.dispose();

    _questionnaireState.close();
    _answerInputDebouncer.cancel();
    // dispose all answer controllers
    _updateAnswerControllers(forceCleanUp: true);

    _reactionDisposers.removeWhere((disposer) {
      disposer();
      return true;
    });

    super.dispose();
  }
}
