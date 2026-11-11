import 'package:flutter_test/flutter_test.dart';
import 'package:my_auto_guide/features/navigation/logic/map_tile_config.dart';

void main() {
  group('MapTileConfig', () {
    test('uses free OpenStreetMap and Esri URLs without Carto or API keys', () {
      for (final style in MapStyle.values) {
        final url = MapTileConfig.urlFor(style);
        expect(url, isNot(contains('cartocdn')));
        expect(url, isNot(contains('api_key')));
      }
      expect(MapTileConfig.urlFor(MapStyle.street), MapTileConfig.osmUrl);
      expect(MapTileConfig.urlFor(MapStyle.dark), MapTileConfig.osmUrl);
      expect(MapTileConfig.urlFor(MapStyle.satellite), MapTileConfig.esriSatelliteUrl);
    });

    test('cycles cleanly across street -> dark -> satellite -> street', () {
      expect(MapStyle.street.next, MapStyle.dark);
      expect(MapStyle.dark.next, MapStyle.satellite);
      expect(MapStyle.satellite.next, MapStyle.street);
    });
  });
}
