import 'package:flutter_test/flutter_test.dart';
import 'package:my_auto_guide/core/services/cloud_catalog_service.dart';

void main() {
  group('CatalogBrand and CatalogModel domain mapping', () {
    test('Maps CatalogBrand from Map accurately with custom color parsing', () {
      final brand = CatalogBrand.fromMap({
        'id': 'Yamaha',
        'nombre': 'Yamaha Motors',
        'tipo': 'moto',
        'logo_url': 'https://cdn.example.com/yamaha.png',
        'color_hex': '#D31145',
        'popularidad': 95,
      });

      expect(brand.id, 'yamaha');
      expect(brand.nombre, 'Yamaha Motors');
      expect(brand.tipo, 'moto');
      expect(brand.color.toARGB32(), 0xFFD31145);
      expect(brand.popularidad, 95);
    });

    test('Maps CatalogModel with technical specs correctly', () {
      final model = CatalogModel.fromMap({
        'id': 'abc-123',
        'marca_id': 'bajaj',
        'tipo': 'moto',
        'linea': 'Pulsar',
        'modelo': 'Pulsar NS 200 FI',
        'anio_inicio': 2018,
        'cilindraje_cc': 199,
        'tipo_combustible': 'Gasolina',
        'capacidad_tanque_gal': 3.17,
        'potencia_hp': 24.1,
        'aceite_recomendado': '20W-50 Semisintético',
        'imagen_url': 'https://cdn.example.com/ns200.webp',
      });

      expect(model.id, 'abc-123');
      expect(model.marcaId, 'bajaj');
      expect(model.cilindrajeCc, 199);
      expect(model.capacidadTanqueGal, 3.17);
      expect(model.potenciaHp, 24.1);
      expect(model.aceiteRecomendado, '20W-50 Semisintético');
      expect(model.imagenUrl, 'https://cdn.example.com/ns200.webp');
    });

    test('Returns default fallback brands for motos and carros without crashing', () {
      final service = CloudCatalogService();
      final motoBrands = service.getBrands(isMoto: true);
      expect(motoBrands, completion(isNotEmpty));

      final carBrands = service.getBrands(isMoto: false);
      expect(carBrands, completion(isNotEmpty));
    });
  });
}
