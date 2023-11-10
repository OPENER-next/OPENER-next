import 'package:flutter/material.dart';

/// A unique identifier for a [TileLayerDefinition] used in the [tileLayers] map.

enum TileLayerId {
  standard,
  publicTransport,
}

const _thunderforestAPIKey = String.fromEnvironment('THUNDERFOREST_API_KEY', defaultValue: '');

/// A map of tile layers used in the app.

const tileLayers = {
  TileLayerId.standard: TileLayerDefinition(
    name: 'Standard',
    templateUrl: 'https://tile.thunderforest.com/atlas/{z}/{x}/{y}{r}.png?apikey=$_thunderforestAPIKey',
    creditsText: 'Maps © Thunderforest',
    creditsUrl: 'https://www.thunderforest.com',
    maxZoom: 22,
    minZoom: 3
  ),
  TileLayerId.publicTransport: TileLayerDefinition(
    name: 'ÖPNV',
    icon: Icons.directions_bus_rounded,
    templateUrl: 'https://tile.thunderforest.com/transport/{z}/{x}/{y}{r}.png?apikey=$_thunderforestAPIKey',
    darkVariantTemplateUrl: 'https://tile.thunderforest.com/transport-dark/{z}/{x}/{y}{r}.png?apikey=$_thunderforestAPIKey',
    creditsText: 'Maps © Thunderforest',
    creditsUrl: 'https://www.thunderforest.com',
    maxZoom: 22,
    minZoom: 3
  ),
};


/// Contains functional and legal information of a pixel tile layer.

class TileLayerDefinition {

  /// The label of the tile layer.

  final String name;

  /// The tile server URL template string by which to query tiles.
  /// For example: https://tile.openstreetmap.org/{z}/{x}/{y}.png

  final String templateUrl;

  /// A separate tile server URL template string that should be used in dark mode.

  final String? darkVariantTemplateUrl;

  final int maxZoom;
  final int minZoom;

  /// An optional icon that visually describes this tile layer.

  final IconData? icon;

  /// The credits text that should to be displayed to legally use this tile layer.

  final String creditsText;

  /// The website that the credits text should point to, if any.

  final String? creditsUrl;

  const TileLayerDefinition({
    required this.name,
    required this.templateUrl,
    required this.creditsText,
    this.icon,
    this.darkVariantTemplateUrl,
    this.creditsUrl,
    this.maxZoom = 18,
    this.minZoom = 0
  });
}
