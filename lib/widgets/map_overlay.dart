import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import '/helpers/camera_tracker.dart';
import '/view_models/preferences_provider.dart';
import '/view_models/stop_areas_provider.dart';
import '/widgets/map_buttons/location_button.dart';
import '/widgets/map_buttons/map_layer_switcher.dart';
import '/widgets/map_buttons/compass_button.dart';
import '/widgets/map_buttons/zoom_button.dart';
import '/widgets/loading_indicator.dart';
import '/commons/tile_layers.dart';
// ignore: unused_import
import '/commons/map_utils.dart';


/// Builds the action/control buttons and attribution text which overlay the map.

class MapOverlay extends StatefulWidget {
  final double buttonSpacing;

  const MapOverlay({
    Key? key,
    this.buttonSpacing = 10.0,
   }) : super(key: key);


  @override
  _MapOverlayState createState() => _MapOverlayState();
}


class _MapOverlayState extends State<MapOverlay> with TickerProviderStateMixin {

  final ValueNotifier<bool> _isRotatedNotifier = ValueNotifier<bool>(false);

  final ValueNotifier<double> _rotationNotifier = ValueNotifier<double>(0);

  late final mapController = context.read<MapController>();

  static const String _osmCreditsText = '© OpenStreetMap-Mitwirkende';

  static const String _osmCreditsURL= 'https://www.openstreetmap.org/copyright';

  static const _mapLayerSwitcherEntries = [
    MapLayerSwitcherEntry(
      label: 'Satellite',
      id: TileLayerId.satelliteImagery,
      icon: Icons.satellite_rounded,
    ),
    MapLayerSwitcherEntry(
      label: 'Map',
      id: TileLayerId.openStreetMap,
      icon: Icons.map_rounded
    ),
    MapLayerSwitcherEntry(
      label: 'Map',
      id: TileLayerId.publicTransport,
      icon: Icons.map_rounded
    ),
  ];

  @override
  void initState() {
    super.initState();

    mapController.mapEventStream.listen((event) {
      _rotationNotifier.value = mapController.rotation;
      _isRotatedNotifier.value = mapController.rotation != 0;
    });
  }


  @override
  Widget build(BuildContext context) {
    // This allows other widgets which make use of the OverlayEntry widget to display
    // widgets above these widgets without overlaying every widget like the drawer.
    // This is basically an in between layer, while widgets like dialogs or drawers
    // are rendered on the top layer/Overlay widget.
    // The map layer switcher makes use of this.
    return Overlay(
      initialEntries: [
        OverlayEntry(
          builder: (context) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                widget.buttonSpacing + MediaQuery.of(context).padding.left,
                widget.buttonSpacing + MediaQuery.of(context).padding.top,
                widget.buttonSpacing + MediaQuery.of(context).padding.right,
                widget.buttonSpacing + MediaQuery.of(context).padding.bottom,
              ),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Consumer<StopAreasProvider>(
                      builder: (context, stopAreasProvider, child) {
                        return ValueListenableBuilder<bool>(
                          valueListenable: stopAreasProvider.isLoading,
                          builder: (context, value, child) => LoadingIndicator(
                            active: value,
                          ),
                        );
                      }
                    )
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: FloatingActionButton.small(
                      heroTag: null,
                      child: const Icon(
                        Icons.menu,
                      ),
                      onPressed: Scaffold.of(context).openDrawer,
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: ValueListenableBuilder(
                      valueListenable: _isRotatedNotifier,
                      builder: (BuildContext context, bool isRotated, Widget? compass) {
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: isRotated ? compass : const SizedBox.shrink()
                        );
                      } ,
                      child: CompassButton(
                        listenable: _rotationNotifier,
                        getRotation: () => mapController.rotation,
                        isDegree: true,
                        onPressed: _resetRotation,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Selector<PreferencesProvider, TileLayerId>(
                      selector: (context, value) => value.tileLayerId,
                      builder: (context, tileLayerId, child) {
                        return MapLayerSwitcher(
                          entries: _mapLayerSwitcherEntries,
                          active: tileLayerId,
                          onSelection: _changeTileProvider,
                        );
                      }
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: GestureDetector(
                      onTap: _openCreditsUrl,
                      child: Stack(
                        children: [
                          // Stroked text as border.
                          Opacity(
                            opacity: 0.5,
                            child: Text(
                              _osmCreditsText,
                              style: TextStyle(
                                fontSize: 10,
                                foreground: Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = 2
                                  ..strokeJoin = StrokeJoin.round
                                  ..color = Colors.white,
                              ),
                            ),
                          ),
                          // Solid text as fill.
                          const Text(
                            _osmCreditsText,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    )
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Consumer<CameraTracker>(
                          builder: (context, value, child) => LocationButton(
                            activeColor: Theme.of(context).colorScheme.primary,
                            active: value.state == CameraTrackerState.active,
                            onPressed: _toggleCameraTracker
                          )
                        ),
                        SizedBox (
                          height: widget.buttonSpacing
                        ),
                        ZoomButton(
                          onZoomInPressed: _zoomIn,
                          onZoomOutPressed: _zoomOut,
                        )
                      ]
                    ),
                  )
                ]
              )
            );
          }
        )
      ]
    );
  }


  /// Zoom the map view.

  void _zoomIn() {
    // round zoom level so zoom will always stick to integer levels
    mapController.animateTo(ticker: this, zoom: mapController.zoom.roundToDouble() + 1);
  }


  /// Zoom out of the map view.

  void _zoomOut() {
    // round zoom level so zoom will always stick to integer levels
    mapController.animateTo(ticker: this, zoom: mapController.zoom.roundToDouble() - 1);
  }


  /// Reset the map rotation.

  void _resetRotation() {
    mapController.animateTo(ticker: this, rotation: 0);
  }


  /// Activate or deactivate camera tracker depending on its current state.

  void _toggleCameraTracker() {
    final cameraTracker = context.read<CameraTracker>();
    if (cameraTracker.state == CameraTrackerState.inactive) {
      cameraTracker.startTacking();
    }
    else if (cameraTracker.state == CameraTrackerState.active) {
      cameraTracker.stopTracking();
    }
  }


  /// Store and apply selected tile layer id.

  void _changeTileProvider(TileLayerId newTileLayerId) {
    context.read<PreferencesProvider>().tileLayerId = newTileLayerId;
  }


  /// Open the OpenStreetMap credits URL in the default browser.

  void _openCreditsUrl() async {
    if (!await launch(_osmCreditsURL)) throw '$_osmCreditsURL kann nicht aufgerufen werden';
  }
}
