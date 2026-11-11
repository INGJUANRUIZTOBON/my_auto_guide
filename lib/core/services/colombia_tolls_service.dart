import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class ColombiaTollStation {
  final String name;
  final String corridor;
  final double lat;
  final double lng;
  final int carTariffCop;
  final int motoTariffCop;

  const ColombiaTollStation({
    required this.name,
    required this.corridor,
    required this.lat,
    required this.lng,
    required this.carTariffCop,
    this.motoTariffCop = 0, // Motos exentas en peajes nacionales en Colombia
  });
}

class TollEstimateResult {
  final List<ColombiaTollStation> tolls;
  final int totalCostCop;
  final bool isCar;

  const TollEstimateResult({
    required this.tolls,
    required this.totalCostCop,
    required this.isCar,
  });

  int get count => tolls.length;
}

/// Estimador offline de peajes en corredores principales de Colombia sobre rutas OSRM.
class ColombiaTollsService {
  const ColombiaTollsService._();

  static const List<ColombiaTollStation> _corridorTolls = [
    // Corredor Bogotá - Medellín
    ColombiaTollStation(name: 'Peaje Siberia / Calle 80', corridor: 'Bogotá - Medellín', lat: 4.7495, lng: -74.1618, carTariffCop: 14500),
    ColombiaTollStation(name: 'Peaje Caiquero', corridor: 'Bogotá - Medellín', lat: 5.0615, lng: -74.4776, carTariffCop: 15200),
    ColombiaTollStation(name: 'Peaje Korán', corridor: 'Bogotá - Medellín', lat: 5.4552, lng: -74.6612, carTariffCop: 15500),
    ColombiaTollStation(name: 'Peaje Puerto Triunfo', corridor: 'Bogotá - Medellín', lat: 5.8758, lng: -74.6425, carTariffCop: 15800),
    ColombiaTollStation(name: 'Peaje Cocorná', corridor: 'Bogotá - Medellín', lat: 5.9935, lng: -75.0835, carTariffCop: 16200),
    ColombiaTollStation(name: 'Peaje Las Palmas / Túnel Oriente', corridor: 'Valle de Aburrá', lat: 6.1835, lng: -75.5020, carTariffCop: 23800),
    // Corredor Bogotá - Girardot / Ibagué / Cali
    ColombiaTollStation(name: 'Peaje Chusacá', corridor: 'Bogotá - Girardot', lat: 4.5444, lng: -74.2625, carTariffCop: 14800),
    ColombiaTollStation(name: 'Peaje Chinauta', corridor: 'Bogotá - Girardot', lat: 4.2940, lng: -74.4622, carTariffCop: 15200),
    ColombiaTollStation(name: 'Peaje Gualanday', corridor: 'Girardot - Ibagué', lat: 4.2950, lng: -75.0258, carTariffCop: 14500),
    ColombiaTollStation(name: 'Peaje Túnel de La Línea', corridor: 'Ibagué - Armenia', lat: 4.4610, lng: -75.5450, carTariffCop: 16500),
    // Corredor Bogotá - Villavicencio
    ColombiaTollStation(name: 'Peaje Boquerón', corridor: 'Bogotá - Villavicencio', lat: 4.4922, lng: -74.0608, carTariffCop: 16800),
    ColombiaTollStation(name: 'Peaje Naranjal', corridor: 'Bogotá - Villavicencio', lat: 4.2815, lng: -73.8455, carTariffCop: 14900),
    ColombiaTollStation(name: 'Peaje Pipiral', corridor: 'Bogotá - Villavicencio', lat: 4.1985, lng: -73.7130, carTariffCop: 22600),
    // Corredor Bogotá - Norte / Boyacá / Santanderes
    ColombiaTollStation(name: 'Peaje Andes (Autonorte)', corridor: 'Bogotá - Tunja', lat: 4.8280, lng: -74.0278, carTariffCop: 12900),
    ColombiaTollStation(name: 'Peaje El Roble', corridor: 'Bogotá - Tunja', lat: 5.0195, lng: -73.9275, carTariffCop: 12500),
    ColombiaTollStation(name: 'Peaje Albarracín', corridor: 'Bogotá - Tunja', lat: 5.2912, lng: -73.5750, carTariffCop: 12500),
    ColombiaTollStation(name: 'Peaje Los Curos', corridor: 'Bucaramanga - San Gil', lat: 6.9175, lng: -73.0145, carTariffCop: 13800),
    // Valle del Cauca / Eje Cafetero / Costa
    ColombiaTollStation(name: 'Peaje Estambul', corridor: 'Cali - Palmira', lat: 3.5320, lng: -76.3895, carTariffCop: 12200),
    ColombiaTollStation(name: 'Peaje Cerritos II', corridor: 'Pereira - Cartago', lat: 4.8035, lng: -75.8775, carTariffCop: 16900),
    ColombiaTollStation(name: 'Peaje Papiros / Puerto Colombia', corridor: 'Barranquilla - Cartagena', lat: 11.0110, lng: -74.9185, carTariffCop: 15600),
  ];

  /// Detecta peajes cercanos (< 700m) a la geometría de [routePoints] usando muestreo eficiente.
  static TollEstimateResult estimateRouteTolls(
    List<LatLng> routePoints, {
    required bool isCar,
  }) {
    if (routePoints.length < 2) {
      return TollEstimateResult(tolls: const [], totalCostCop: 0, isCar: isCar);
    }

    // Muestrear máximo ~160 puntos para mantener cómputo < 2ms en cualquier dispositivo
    final step = (routePoints.length / 160).ceil().clamp(1, 50);
    final sampled = <LatLng>[];
    for (int i = 0; i < routePoints.length; i += step) {
      sampled.add(routePoints[i]);
    }
    if (sampled.last != routePoints.last) {
      sampled.add(routePoints.last);
    }

    final matched = <ColombiaTollStation>[];
    for (final toll in _corridorTolls) {
      for (final p in sampled) {
        final d = Geolocator.distanceBetween(p.latitude, p.longitude, toll.lat, toll.lng);
        if (d <= 750.0) {
          matched.add(toll);
          break;
        }
      }
    }

    final total = matched.fold<int>(
      0,
      (sum, t) => sum + (isCar ? t.carTariffCop : t.motoTariffCop),
    );

    return TollEstimateResult(
      tolls: matched,
      totalCostCop: total,
      isCar: isCar,
    );
  }
}
