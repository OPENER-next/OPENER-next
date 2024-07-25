import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../api/app_worker/element_handler.dart';
import '../../models/map_features/map_feature_representation.dart';
import '../map_layer.dart';
import 'osm_element_marker.dart';


class MapFeatureState extends MapFeatureRepresentation {
  final _active = Observable(false);
  bool get active => _active.value;
  set active(bool value) => _active.value = value;

  final _uploadState = Observable<Future<void>?>(null);
  Future<void>? get uploadState => _uploadState.value;
  set uploadState(Future<void>? value) => _uploadState.value = value;

  final void Function(MapFeatureState)? onTap;
  final BoxCollider collider = BoxCollider(60, 60);

  MapFeatureState.fromRepresentation({
    required MapFeatureRepresentation representation,
    this.onTap,
    }) : super(
      id: representation.id,
      type: representation.type,
      geometry: representation.geometry,
      icon: representation.icon,
      label: (_, __) => 'TODO',
      tags: const {},
    );

}







// Problem:
// - Minimized marker overlaps non minimized markers
// only solution is to render them on a totally separate layer OR can sort them? Perhaps I can give a priority property or so
// - instable dadurch, dass ich am rand welche ausblende wird plötzlich platz für andere marker
// - instable durch zoomen, weil plötzlich platz für einen vorhergehenden marker wird wodurch allerdings der darauffolgende keinen mehr hat ()
// - "on add" rendert zunächst element, collision detection hat erst einfluss im nächsten frame
// - MapLayerPositioned align will be different (bottom vs center)

// Solution:
// - Minimized marker Overlapp: Second layer mit transform target + follower und minimized marker follown dann ihrem marker?

// sort markers based on distance to one starting marker?


class OsmElementLayer extends StatefulWidget {

  final Stream<ElementUpdate> elements;

  final void Function(MapFeatureRepresentation? element)? onSelect;

  final int zoomLowerLimit;

  const OsmElementLayer({
    required this.elements,
    this.onSelect,
    // TODO: currently changes to this won't update the super cluster
    this.zoomLowerLimit = 16,
    super.key,
  });

  @override
  State<OsmElementLayer> createState() => _OsmElementLayerState();
}

class _OsmElementLayerState extends AddRemovalAnimationBase<OsmElementLayer, MapFeatureState> {

  late StreamSubscription _elementsSub;

  @override
  void initState() {
    super.initState();
    _elementsSub = widget.elements.listen(_handleElementChanges);
  }

  @override
  void didUpdateWidget(covariant OsmElementLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.elements != oldWidget.elements) {
      _elementsSub.cancel();
      _elementsSub = widget.elements.listen(_handleElementChanges);
    }
  }

  void _handleElementChanges(ElementUpdate change) {
    if (change.action == ElementUpdateAction.clear) {
    }
    else if (change.action == ElementUpdateAction.update) {
      print("add");

      // TODO: what happens on update? / duplicates?
      add(MapFeatureState.fromRepresentation(
        onTap: (element) {
          runInAction(() => element.active = !element.active);
          widget.onSelect?.call(element.active
            ? element
            : null,
          );
        },
        representation: change.element!
      ), duration: Duration(seconds: 1));
    }
    else if (change.action == ElementUpdateAction.remove) {
      remove(MapFeatureState.fromRepresentation(
        representation: change.element!
      ), duration: Duration(seconds: 1));
    }
  }


  AppLocalizations get appLocale => AppLocalizations.of(context)!;

  @override
  Widget build(BuildContext context) {
    return MapLayer(
      children: getChildren(context).toList(growable: false),
    );
  }

  @override
  Widget itemBuilder(context, item, animation) {
    animation = CurvedAnimation(
      parent: animation,
      curve: Curves.elasticOut,
      reverseCurve: Curves.easeOutBack,
    );

    return MapLayerPositioned(
      key: ValueKey(item),
      position: item.geometry.center,
      align: Alignment.bottomCenter,
      collider: item.collider,
      child: ValueListenableBuilder(
        valueListenable: item.collider,
        builder: (context, collision, child) {
          return ScaleTransition(
            scale: animation,
            alignment: Alignment.bottomCenter,
            filterQuality: FilterQuality.low,
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                if (child is Container) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                }
                else {
                  return ScaleTransition(
                    scale: CurvedAnimation(
                      parent: animation,
                      curve: Curves.elasticOut,
                      reverseCurve: Curves.easeOutBack,
                    ),
                    alignment: Alignment.bottomCenter,
                    filterQuality: FilterQuality.low,
                    child: child,
                  );
                }
              },
              child: collision
                ? Container(color: Colors.blue,width: 5, height: 5,)
                : child
            )
          );
        },
        child: SizedBox(
          width: 260,
          height: 60,
          child: Observer(
            builder: (context) {
              return OsmElementMarker(
                onTap: () => item.uploadState == null
                  ? item.onTap?.call(item)
                  : null,
                active: item.active,
                icon: item.icon,
                label: item.elementLabel(appLocale),
                uploadState: item.uploadState,
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  bool isItemInViewport(item) {
    // TODO: implement isItemInViewport
    return true;
  }

  // Duration _getRandomDelay([int? seed]) {
  //   if (widget.durationOffsetRange.inMicroseconds == 0) {
  //     return Duration.zero;
  //   }
  //   final randomTimeOffset = Random(seed).nextInt(widget.durationOffsetRange.inMicroseconds);
  //   return Duration(microseconds: randomTimeOffset);
  // }
}




// think about delay differently

// add a queue to which each new element is added and randomly remove them from the queue and add them to the map
// or directly delay and add to map (only problem is an early removal)

// directly Future.delayed().then(removeFromMapCollection + addToMap) <- store each future inside a map collection in case it got removed before it got added


// delay has to be implemented in the add/remove together with curves functions via Interval because I need to update the duration


abstract class AddRemovalAnimationBase<P extends StatefulWidget, T> extends State<P> with TickerProviderStateMixin {
  Widget itemBuilder(BuildContext context, T item, Animation<double> animation);

  final _items = <T, AnimationController?>{};

  static const _kAlwaysStopped = AlwaysStoppedAnimation<double>(1);

  Iterable<Widget> getChildren(BuildContext context) {
    return _items.entries.map((item) => itemBuilder(
        context,
        item.key,
        item.value ?? _kAlwaysStopped,
      ),
    );
  }

  /// doc
  ///
  ///
  ///
  void add(T item, {
    Duration duration = Duration.zero,
  }) {
    if (isItemInViewport(item)) {
      final AnimationController? controller;
      if (duration != Duration.zero) {
        controller = AnimationController(
          duration: duration,
          vsync: this,
        );
        controller.forward().then((_) {
          controller!.dispose();
          _items[item] = null;
        });
      }
      else {
        controller = null;
      }
      setState(() {
        _items[item] = controller;
      });
    }
    else {
      _items[item] = null;
    }
  }

  /// doc
  ///
  ///
  ///
  void remove(T item, {
    Duration duration = Duration.zero,
  }) {
    if (isItemInViewport(item)) {
      if (duration != Duration.zero) {
        final controller = _items[item] ?? AnimationController(
          duration: duration,
          value: 1.0,
          vsync: this,
        );
        controller.reverse().then((_) {
          controller.dispose();
          setState(() {
            _items.remove(item);
          });
        });
        setState(() {
          _items[item] = controller;
        });
      }
      else {
        setState(() {
          _items.remove(item);
        });
      }
    }
    else {
      _items.remove(item);
    }
  }

  bool isItemInViewport(T item);

  @override
  void dispose() {
    for (final controller in _items.values) {
      controller?.dispose();
    }
    super.dispose();
  }
}

typedef AnimatedMarkerLayerItemBuilder<T> = Widget Function(BuildContext context, T item, Animation<double> animation);
