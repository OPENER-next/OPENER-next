import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'ripple_indicator.dart';
import '../map_layer.dart';

/// Layer to show ripple animations for geo circles and automatically remove them when expired.

class LoadingAreaLayer extends StatefulWidget {

  final Iterable<Circle> areas;

  const LoadingAreaLayer({
    required this.areas,
    super.key,
  });

  @override
  State<LoadingAreaLayer> createState() => _LoadingAreaLayerState();
}

class _LoadingAreaLayerState extends State<LoadingAreaLayer> {
  // maps whether an area is still loading (true) or expiring (false)
  final _loadingAreas = <Circle, bool>{};

  @override
  void didUpdateWidget(covariant LoadingAreaLayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newAreas = Set.of(widget.areas);
    // set all previous areas not contained in newAreas to false (expiring)
    // otherwise true (loading)
    // remove them from the set so we afterwards only have to add the remaining areas
    _loadingAreas.updateAll((area, loading) => newAreas.remove(area));
    // add remaining areas
    for (final area in newAreas) {
      _loadingAreas[area] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MapLayer(
      children: _loadingAreas.entries
        .map((entry) => _buildChild(entry.key, end: !entry.value))
        .toList(growable: false),
    );
  }

  MapLayerPositioned _buildChild(Circle area, { bool end = false }) {
    return MapLayerPositioned(
      key: ValueKey(area),
      position: area.center,
      size: Size.fromRadius(area.radius),
      child: RippleIndicator(
        end: end,
        onEnd: !end ? null : () {
          setState(() {
            // remove widget if animation ended
            _loadingAreas.remove(area);
          });
        },
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
