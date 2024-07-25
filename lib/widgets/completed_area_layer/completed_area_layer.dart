import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../map_layer.dart';
import '/widgets/animated_path.dart';


/// Layer to highlight completed stop areas.

class CompletedAreaLayer extends StatelessWidget {

  final Iterable<LatLng> locations;

  /// The current zoom level.

  final num currentZoom;

  /// The smallest zoom level on which the layer is still visible.

  final num lowerZoomLimit;

  const CompletedAreaLayer({
    required this.locations,
    required this.currentZoom,
    this.lowerZoomLimit = 15,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: currentZoom <= lowerZoomLimit
        ? null
        : MapLayer(
          children: locations
            .map(_buildChild)
            .toList(growable: false),
        ),
    );
  }

  MapLayerPositioned _buildChild(LatLng location) {
    return MapLayerPositioned(
      key: ValueKey(location),
      position: location,
      child: const CheckMark()
    );
  }
}


class CheckMark extends StatefulWidget {
  const CheckMark({super.key});

  @override
  State<CheckMark> createState() => _CheckMarkState();
}

class _CheckMarkState extends State<CheckMark> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubicEmphasized);
    _controller.forward();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF8ccf73),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 3.0
        )
      ),
      width: 40,
      height: 40,
      child: AnimatedPath(
        animation: _animation,
        strokeWidth: 5,
        color: Colors.white,
        pathBuilder: (size) {
          return Path()
          ..moveTo(0.270 * size.width, 0.541 * size.height)
          ..lineTo(0.416 * size.width, 0.687 * size.height)
          ..lineTo(0.750 * size.width, 0.354 * size.height);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
