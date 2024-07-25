import 'package:flutter/material.dart' hide View;
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:animated_location_indicator/animated_location_indicator.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_mvvm_architecture/base.dart';
import 'package:flutter_mvvm_architecture/extras.dart';
import 'package:mobx/mobx.dart';

import '/commons/tile_layers.dart';
import '/view_models/home_view_model.dart';
import '/commons/app_config.dart';
import '/widgets/completed_area_layer/completed_area_layer.dart';
import '/widgets/loading_area_layer/loading_area_layer.dart';
import '/widgets/geometry_layer.dart';
import '/widgets/custom_snackbar.dart';
import '/widgets/query_indicator.dart';
import '/widgets/stops_layer/stop_area_layer.dart';
import '/widgets/osm_element_layer/osm_element_layer.dart';
import '/widgets/question_dialog/question_dialog.dart';
import '/widgets/map_overlay/map_overlay.dart';
import '/widgets/home_sidebar/home_sidebar.dart';

class HomeScreen extends View<HomeViewModel> with PromptHandler {
  const HomeScreen({super.key}) : super(create: HomeViewModel.new);

  @override
  Widget build(BuildContext context, viewModel) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.black26,
        statusBarIconBrightness: Brightness.light,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarColor: Colors.black26,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        drawer: const HomeSidebar(),
        body: NotificationBuilder<HomeViewModel>(
          builder:(context, request) => CustomSnackBar(
            request.message,
            actionText: request.actionLabel,
            actionCallback: request.action,
          ),
          child: Stack(
            children: [
              FlutterMap(
                mapController: viewModel.mapController,
                options: MapOptions(
                  onTap: (_, __) => viewModel.closeQuestionnaire(),
                  interactionOptions: const InteractionOptions(
                    enableMultiFingerGestureRace: true,
                  ),
                  initialCenter: untracked(() => viewModel.storedMapLocation),
                  initialZoom: untracked(() => viewModel.storedMapZoom),
                  initialRotation: untracked(() => viewModel.storedMapRotation),
                  minZoom: kTileLayerPublicTransport.minZoom.toDouble(),
                  maxZoom: kTileLayerPublicTransport.maxZoom.toDouble(),
                  backgroundColor: Theme.of(context).colorScheme.background,
                ),
                children: [
                  TileLayer(
                    tileProvider: NetworkTileProvider(
                      headers: {
                        'User-Agent': appUserAgent,
                      },
                    ),
                    retinaMode: RetinaMode.isHighDensity(context),
                    evictErrorTileStrategy: EvictErrorTileStrategy.dispose,
                    urlTemplate: isDarkMode && kTileLayerPublicTransport.darkVariantTemplateUrl != null
                      ? kTileLayerPublicTransport.darkVariantTemplateUrl
                      : kTileLayerPublicTransport.templateUrl,
                    minNativeZoom: kTileLayerPublicTransport.minZoom,
                    maxNativeZoom: kTileLayerPublicTransport.maxZoom,
                  ),
                  QueryIndicator(
                    active: viewModel.isLoadingStopAreas,
                  ),
                  Observer(
                    builder: (context) {
                      // "length" used to listen to changes
                      viewModel.loadingStopAreas.length;
                      return LoadingAreaLayer(
                        areas: viewModel.loadingStopAreas.map((s) => s.circumcircle),
                      );
                    },
                  ),
                  Observer(
                    builder: (context) {
                      // "length" used to listen to changes
                      viewModel.completeStopAreas.length;
                      return CompletedAreaLayer(
                        currentZoom: viewModel.mapZoomRound,
                        locations: viewModel.completeStopAreas.map((s) => s.center),
                      );
                    },
                  ),
                  Observer(
                    builder: (context) {
                      // "length" used to listen to changes
                      viewModel
                      ..unloadedStopAreas.length
                      ..incompleteStopAreas.length
                      ..completeStopAreas.length;

                      return StopsLayer(
                        currentZoom: viewModel.mapZoomRound,
                        unloadedStops: viewModel.unloadedStopAreas.map((s) => s.center),
                        incompleteStops: viewModel.incompleteStopAreas.map((s) => s.center),
                        completedStops: viewModel.completeStopAreas.map((s) => s.center),
                      );
                    },
                  ),
                  Observer(
                    builder: (context) {
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: (viewModel.hasSelectedElement)
                          ? GeometryLayer(
                            geometry: viewModel.selectedElement!.geometry,
                            key: viewModel.selectedElementKey,
                          )
                          : null,
                      );
                    },
                  ),
                  Observer(
                    builder: (context) {
                      // rebuild location indicator when location access is granted
                      viewModel.userLocationState;
                      return const AnimatedLocationLayer();
                    },
                  ),
                  Observer(
                    builder: (context) {
                      // "length" used to listen to changes
                      viewModel.uploadQueue.length;
                      return OsmElementLayer(
                        elements: viewModel.elements,
                       // onSelect: viewModel.onElementTap,
                      );
                    },
                  ),
                  RepaintBoundary(
                    child: AnimatedSwitcher(
                      switchInCurve: Curves.ease,
                      switchOutCurve: Curves.ease,
                      duration: const Duration(milliseconds: 300),
                      child: !viewModel.hasQuestionnaire
                        ? const MapOverlay()
                        : null,
                    ),
                  ),
                ],
              ),
              // place sheet on extra stack above map so map pan events won't pass through
              Observer(
                builder: (context) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    reverseDuration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeInOutCubicEmphasized,
                    switchOutCurve: Curves.ease,
                    transitionBuilder: (child, animation) {
                      final offsetAnimation = Tween<Offset>(
                        begin: const Offset(0, 1),
                        end: Offset.zero,
                      ).animate(animation);
                      return SlideTransition(
                        position: offsetAnimation,
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        )
                      );
                    },
                    child: viewModel.hasQuestionnaire
                      ? QuestionDialog(
                        activeQuestionIndex: viewModel.currentQuestionnaireIndex!,
                        questions: viewModel.questionnaireQuestions,
                        answers: viewModel.questionnaireAnswers,
                        showSummary: viewModel.questionnaireIsFinished,
                        key: viewModel.selectedElementKey,
                      )
                      : null
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
