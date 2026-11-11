class MaintenanceConfig {
  final String title;
  final int cycleDays;

  MaintenanceConfig({required this.title, required this.cycleDays});
}

class MaintenanceConfigService {
  static final MaintenanceConfigService _instance = MaintenanceConfigService._internal();
  factory MaintenanceConfigService() => _instance;
  MaintenanceConfigService._internal();

  final Map<String, int> _cycles = {
    'cadena': 15,
    'filtro': 90,
    'aceite': 25,
    'soat': 365,
    'tecno': 365,
  };

  final Map<String, int> _kmsCycles = {
    'cadena': 500,
    'filtro': 5000,
    'aceite': 3000,
  };

  int getCycle(String key) => _cycles[key] ?? 30;
  
  int getKmsCycle(String key) => _kmsCycles[key] ?? 5000;
  
  Map<String, int> getAllCycles() => _cycles;

  /// Etiqueta contextual según sea carro o moto.
  static String labelFor(String key, {required bool isCar}) {
    switch (key) {
      case 'cadena':
        return isCar ? 'Distribución' : 'Kit Arrastre';
      case 'filtro':
        return isCar ? 'Filtros' : 'Filtro Aire';
      case 'aceite':
        return 'Aceite';
      case 'soat':
        return 'SOAT';
      case 'tecno':
        return 'Tecno';
      default:
        return key;
    }
  }

  /// Ciclo recomendado en días según tipo de vehículo.
  int cycleDaysFor(String key, {required bool isCar}) {
    if (isCar) {
      if (key == 'cadena') return 365;
      if (key == 'filtro') return 180;
      if (key == 'aceite') return 180;
    }
    return getCycle(key);
  }

  /// Ciclo recomendado en km según tipo de vehículo.
  int cycleKmsFor(String key, {required bool isCar}) {
    if (isCar) {
      if (key == 'cadena') return 40000;
      if (key == 'filtro') return 10000;
      if (key == 'aceite') return 8000;
    }
    return getKmsCycle(key);
  }
}
