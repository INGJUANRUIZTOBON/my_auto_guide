import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Estilos de mapa base 100% gratuitos sin marcas de agua "API KEY REQUIRED".
enum MapStyle {
  street('Calle'),
  dark('Oscuro'),
  satellite('Satélite');

  final String label;
  const MapStyle(this.label);

  MapStyle get next {
    switch (this) {
      case MapStyle.street:
        return MapStyle.dark;
      case MapStyle.dark:
        return MapStyle.satellite;
      case MapStyle.satellite:
        return MapStyle.street;
    }
  }

  IconData get icon {
    switch (this) {
      case MapStyle.street:
        return Icons.map_rounded;
      case MapStyle.dark:
        return Icons.dark_mode_rounded;
      case MapStyle.satellite:
        return Icons.satellite_alt_rounded;
    }
  }
}

class MapTileConfig {
  const MapTileConfig._();

  static const String osmUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String esriSatelliteUrl =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

  /// Matriz de inversión nocturna de alto contraste para mapas de calles OSM.
  static const List<double> darkFilterMatrix = <double>[
    -0.84, 0.0, 0.0, 0.0, 238.0,
    0.0, -0.84, 0.0, 0.0, 238.0,
    0.0, 0.0, -0.84, 0.0, 238.0,
    0.0, 0.0, 0.0, 1.0, 0.0,
  ];

  static String urlFor(MapStyle style) {
    switch (style) {
      case MapStyle.satellite:
        return esriSatelliteUrl;
      case MapStyle.street:
      case MapStyle.dark:
        return osmUrl;
    }
  }

  static TileLayer buildTileLayer({
    required MapStyle style,
    int keepBuffer = 5,
    int panBuffer = 2,
  }) {
    return TileLayer(
      key: ValueKey('tile_${style.name}'),
      urlTemplate: urlFor(style),
      userAgentPackageName: 'com.example.my_auto_guide',
      maxZoom: style == MapStyle.satellite ? 18 : 19,
      keepBuffer: keepBuffer,
      panBuffer: panBuffer,
      tileBuilder: style == MapStyle.dark
          ? (context, tileWidget, tile) => ColorFiltered(
                colorFilter: const ColorFilter.matrix(darkFilterMatrix),
                child: tileWidget,
              )
          : null,
    );
  }
}
