import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class PicoYPlacaStatus {
  final String cityName;
  final bool hasRestrictionSystem;
  final bool appliesToVehicleType;
  final bool isRestrictedToday;
  final bool isRestrictedTomorrow;
  final String scheduleText;
  final String headline;
  final String detail;
  final String detectedBy; // 'GPS', 'Caché', 'Manual'

  const PicoYPlacaStatus({
    required this.cityName,
    required this.hasRestrictionSystem,
    required this.appliesToVehicleType,
    required this.isRestrictedToday,
    required this.isRestrictedTomorrow,
    required this.scheduleText,
    required this.headline,
    required this.detail,
    required this.detectedBy,
  });
}

/// Motor de reglas de Pico y Placa en Colombia con detección automática por GPS.
class PicoYPlacaService {
  static final PicoYPlacaService _instance = PicoYPlacaService._internal();
  factory PicoYPlacaService() => _instance;
  PicoYPlacaService._internal();

  static const String _prefLastCityKey = 'pico_placa_last_city';

  /// Festivos oficiales en Colombia (2026–2027) para evitar falsas alertas en días festivos.
  static final Set<String> _colombiaHolidays = {
    '2026-01-01', '2026-01-12', '2026-03-23', '2026-04-02', '2026-04-03',
    '2026-05-01', '2026-05-18', '2026-06-08', '2026-06-15', '2026-06-29',
    '2026-07-20', '2026-08-07', '2026-08-17', '2026-10-12', '2026-11-02',
    '2026-11-16', '2026-12-08', '2026-12-25',
    '2027-01-01', '2027-01-11', '2027-03-22', '2027-03-25', '2027-03-26',
    '2027-05-01', '2027-05-10', '2027-05-31', '2027-06-07', '2027-06-28',
    '2027-07-20', '2027-08-07', '2027-08-16', '2027-10-18', '2027-11-01',
    '2027-11-15', '2027-12-08', '2027-12-25',
  };

  /// Detecta la ciudad actual por GPS (con geocodificación local + fallback Nominatim/caché)
  /// y evalúa la restricción para [plate] e [isCar].
  Future<PicoYPlacaStatus> detectAndEvaluate({
    required String plate,
    required bool isCar,
    bool schedulePushReminders = true,
  }) async {
    String cityName = 'Tu municipio';
    String detectedBy = 'Caché';

    try {
      final prefs = await SharedPreferences.getInstance();
      cityName = prefs.getString(_prefLastCityKey) ?? 'Tu municipio';

      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always) {
        Position? pos = await Geolocator.getLastKnownPosition();
        pos ??= await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 4),
        );

        final localCity = matchCityByCoordinates(pos.latitude, pos.longitude);
        if (localCity != null) {
          cityName = localCity;
          detectedBy = 'GPS';
        } else {
          final remoteCity = await _reverseGeocodeCity(pos.latitude, pos.longitude);
          if (remoteCity != null && remoteCity.isNotEmpty) {
            cityName = remoteCity;
            detectedBy = 'GPS';
          }
        }
        await prefs.setString(_prefLastCityKey, cityName);
      }
    } catch (e) {
      debugPrint('[PICO_PLACA] Fallback a caché local: $e');
    }

    final status = evaluateForDate(
      plate: plate,
      isCar: isCar,
      cityName: cityName,
      date: DateTime.now(),
      detectedBy: detectedBy,
    );

    if (schedulePushReminders) {
      await _scheduleNightAndMorningReminders(
        plate: plate,
        isCar: isCar,
        cityName: cityName,
      );
    }

    return status;
  }

  /// Detección offline instantánea de áreas metropolitanas principales en Colombia.
  static String? matchCityByCoordinates(double lat, double lng) {
    if (lat >= 4.46 && lat <= 4.84 && lng >= -74.24 && lng <= -73.99) {
      return 'Bogotá';
    }
    if (lat >= 6.08 && lat <= 6.45 && lng >= -75.70 && lng <= -75.43) {
      return 'Medellín';
    }
    if (lat >= 3.30 && lat <= 3.55 && lng >= -76.60 && lng <= -76.44) {
      return 'Cali';
    }
    if (lat >= 6.98 && lat <= 7.20 && lng >= -73.20 && lng <= -73.04) {
      return 'Bucaramanga';
    }
    if (lat >= 10.88 && lat <= 11.06 && lng >= -74.88 && lng <= -74.74) {
      return 'Barranquilla';
    }
    if (lat >= 4.74 && lat <= 4.86 && lng >= -75.77 && lng <= -75.62) {
      return 'Pereira';
    }
    if (lat >= 5.02 && lat <= 5.11 && lng >= -75.56 && lng <= -75.44) {
      return 'Manizales';
    }
    if (lat >= 4.49 && lat <= 4.59 && lng >= -75.73 && lng <= -75.63) {
      return 'Armenia';
    }
    if (lat >= 10.34 && lat <= 10.48 && lng >= -75.58 && lng <= -75.45) {
      return 'Cartagena';
    }
    if (lat >= 4.38 && lat <= 4.49 && lng >= -75.29 && lng <= -75.13) {
      return 'Ibagué';
    }
    return null;
  }

  Future<String?> _reverseGeocodeCity(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=10&addressdetails=1',
      );
      final res = await http
          .get(uri, headers: {'User-Agent': 'MyAutoGuide/1.2'})
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>?;
        final city = addr?['city'] ??
            addr?['town'] ??
            addr?['municipality'] ??
            addr?['county'];
        return city?.toString().trim();
      }
    } catch (_) {}
    return null;
  }

  /// Evalúa la restricción exacta para [date] según ciudad colombiana, placa y tipo.
  static PicoYPlacaStatus evaluateForDate({
    required String plate,
    required bool isCar,
    required String cityName,
    required DateTime date,
    String detectedBy = 'GPS',
  }) {
    final cleanPlate = plate.trim().toUpperCase();
    final digits = RegExp(r'\d').allMatches(cleanPlate).map((m) => int.parse(m.group(0)!)).toList();
    final int? firstDigit = digits.isNotEmpty ? digits.first : null;
    final int? lastDigit = digits.isNotEmpty ? digits.last : null;

    final cityNorm = _normalizeCity(cityName);

    // Ciudades principales sin Pico y Placa para particulares
    if (cityNorm.contains('BARRANQUILLA')) {
      return PicoYPlacaStatus(
        cityName: cityName,
        hasRestrictionSystem: false,
        appliesToVehicleType: false,
        isRestrictedToday: false,
        isRestrictedTomorrow: false,
        scheduleText: 'Libre circulación',
        headline: 'Sin Pico y Placa en $cityName',
        detail: 'En $cityName no aplica Pico y Placa para carros ni motos particulares.',
        detectedBy: detectedBy,
      );
    }

    // Verificar si la ciudad está en el catálogo de ciudades con Pico y Placa
    final bool isKnownRestrictedCity = _isCityWithPicoYPlaca(cityNorm);
    if (!isKnownRestrictedCity) {
      return PicoYPlacaStatus(
        cityName: cityName,
        hasRestrictionSystem: false,
        appliesToVehicleType: false,
        isRestrictedToday: false,
        isRestrictedTomorrow: false,
        scheduleText: 'Sin restricción urbana registrada',
        headline: 'En $cityName no aplica Pico y Placa',
        detail: 'Según tu ubicación ($cityName), esta ciudad/municipio no tiene Pico y Placa para particulares.',
        detectedBy: detectedBy,
      );
    }

    final bool todayRestricted =
        _checkCityDayRestriction(cityNorm, isCar, firstDigit, lastDigit, date);
    final bool tomorrowRestricted = _checkCityDayRestriction(
      cityNorm,
      isCar,
      firstDigit,
      lastDigit,
      date.add(const Duration(days: 1)),
    );

    if (cityNorm.contains('BOGOTA') && !isCar) {
      return PicoYPlacaStatus(
        cityName: 'Bogotá',
        hasRestrictionSystem: true,
        appliesToVehicleType: false,
        isRestrictedToday: false,
        isRestrictedTomorrow: false,
        scheduleText: 'Motos exentas en Bogotá',
        headline: 'Moto exenta en Bogotá',
        detail: 'En Bogotá las motocicletas están exentas de Pico y Placa.',
        detectedBy: detectedBy,
      );
    }

    if (cityNorm.contains('CALI') && !isCar) {
      return PicoYPlacaStatus(
        cityName: 'Cali',
        hasRestrictionSystem: true,
        appliesToVehicleType: false,
        isRestrictedToday: false,
        isRestrictedTomorrow: false,
        scheduleText: 'Motos exentas en Cali',
        headline: 'Moto exenta en Cali',
        detail: 'En Cali las motocicletas particulares no tienen Pico y Placa.',
        detectedBy: detectedBy,
      );
    }

    final schedule = _scheduleForCity(cityNorm);
    final digitLabel = (cityNorm.contains('MEDELLIN') && !isCar)
        ? 'primer dígito (${firstDigit ?? "?"})'
        : 'último dígito (${lastDigit ?? "?"})';

    final String headline;
    final String detail;
    if (cleanPlate.isEmpty || digits.isEmpty) {
      headline = 'Registra tu placa para validar $cityName';
      detail = 'Horario en $cityName: $schedule.';
    } else if (todayRestricted) {
      headline = 'HOY TIENES PICO Y PLACA en $cityName';
      detail = 'Tu placa $cleanPlate ($digitLabel) tiene restricción hoy. Horario: $schedule.';
    } else if (tomorrowRestricted) {
      headline = 'Hoy circulas libre en $cityName (Mañana aplica)';
      detail = 'Hoy puedes circular sin restricción, pero MAÑANA sí aplica para tu placa $cleanPlate.';
    } else {
      headline = 'Circulación libre hoy en $cityName';
      detail = 'Tu placa $cleanPlate ($digitLabel) no tiene restricción hoy ni mañana. Horario: $schedule.';
    }

    return PicoYPlacaStatus(
      cityName: cityName,
      hasRestrictionSystem: true,
      appliesToVehicleType: true,
      isRestrictedToday: todayRestricted,
      isRestrictedTomorrow: tomorrowRestricted,
      scheduleText: schedule,
      headline: headline,
      detail: detail,
      detectedBy: detectedBy,
    );
  }

  static bool _isCityWithPicoYPlaca(String cityNorm) {
    return cityNorm.contains('BOGOTA') ||
        cityNorm.contains('MEDELLIN') ||
        cityNorm.contains('ENVIGADO') ||
        cityNorm.contains('ITAGUI') ||
        cityNorm.contains('BELLO') ||
        cityNorm.contains('SABANETA') ||
        cityNorm.contains('CALI') ||
        cityNorm.contains('BUCARAMANGA') ||
        cityNorm.contains('FLORIDABLANCA') ||
        cityNorm.contains('GIRON') ||
        cityNorm.contains('PIEDECUESTA') ||
        cityNorm.contains('PEREIRA') ||
        cityNorm.contains('DOSQUEBRADAS') ||
        cityNorm.contains('CARTAGENA') ||
        cityNorm.contains('CUCUTA') ||
        cityNorm.contains('IBAGUE') ||
        cityNorm.contains('VILLAVICENCIO') ||
        cityNorm.contains('MANIZALES') ||
        cityNorm.contains('ARMENIA');
  }

  static String _scheduleForCity(String cityNorm) {
    if (cityNorm.contains('BOGOTA')) return 'Lun–Vie 6:00 a. m. – 9:00 p. m.';
    if (cityNorm.contains('MEDELLIN') ||
        cityNorm.contains('ENVIGADO') ||
        cityNorm.contains('ITAGUI') ||
        cityNorm.contains('BELLO') ||
        cityNorm.contains('SABANETA')) {
      return 'Lun–Vie 5:00 a. m. – 8:00 p. m.';
    }
    if (cityNorm.contains('CALI')) return 'Lun–Vie 6:00 a. m. – 7:00 p. m.';
    if (cityNorm.contains('BUCARAMANGA') ||
        cityNorm.contains('FLORIDABLANCA') ||
        cityNorm.contains('GIRON') ||
        cityNorm.contains('PIEDECUESTA')) {
      return 'Lun–Vie 6:00 a. m.–8:00 p. m. • Sáb 9:00 a. m.–1:00 p. m.';
    }
    return 'Lun–Vie horario diurno local';
  }

  static bool _checkCityDayRestriction(
    String cityNorm,
    bool isCar,
    int? firstDigit,
    int? lastDigit,
    DateTime date,
  ) {
    if (firstDigit == null || lastDigit == null) return false;
    final isoDate =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (_colombiaHolidays.contains(isoDate)) return false;

    final wd = date.weekday; // 1=Lun .. 7=Dom
    if (wd == DateTime.sunday) return false;

    // Bucaramanga incluye sábados 9am–1pm
    final isBucaramanga = cityNorm.contains('BUCARAMANGA') ||
        cityNorm.contains('FLORIDABLANCA') ||
        cityNorm.contains('GIRON') ||
        cityNorm.contains('PIEDECUESTA');
    if (wd == DateTime.saturday && !isBucaramanga) return false;

    // Bogotá: solo carros L-V por día calendario par/impar
    if (cityNorm.contains('BOGOTA')) {
      if (!isCar) return false;
      final isOddCalendarDay = date.day % 2 != 0;
      // Días impares circulan 1-5 (restricción 6,7,8,9,0). Días pares circulan 6-0 (restricción 1,2,3,4,5).
      final allowed = isOddCalendarDay
          ? (lastDigit >= 1 && lastDigit <= 5)
          : (lastDigit == 0 || (lastDigit >= 6 && lastDigit <= 9));
      return !allowed;
    }

    // Medellín y Valle de Aburrá: carros último dígito, motos primer dígito
    if (cityNorm.contains('MEDELLIN') ||
        cityNorm.contains('ENVIGADO') ||
        cityNorm.contains('ITAGUI') ||
        cityNorm.contains('BELLO') ||
        cityNorm.contains('SABANETA')) {
      final targetDigit = isCar ? lastDigit : firstDigit;
      const medellinMap = {
        DateTime.monday: [5, 8],
        DateTime.tuesday: [1, 4],
        DateTime.wednesday: [0, 2],
        DateTime.thursday: [6, 9],
        DateTime.friday: [3, 7],
      };
      return (medellinMap[wd] ?? const []).contains(targetDigit);
    }

    // Cali: solo carros
    if (cityNorm.contains('CALI')) {
      if (!isCar) return false;
      const caliMap = {
        DateTime.monday: [1, 2],
        DateTime.tuesday: [3, 4],
        DateTime.wednesday: [5, 6],
        DateTime.thursday: [7, 8],
        DateTime.friday: [9, 0],
      };
      return (caliMap[wd] ?? const []).contains(lastDigit);
    }

    // Bucaramanga: carros y motos último dígito + sábados
    if (isBucaramanga) {
      if (wd == DateTime.saturday) {
        // Rotación sabatina por pares consecutivos según semana del año
        final weekNum = ((date.difference(DateTime(date.year, 1, 1)).inDays) ~/ 7);
        final satDigits = [(weekNum * 2) % 10, (weekNum * 2 + 1) % 10];
        return satDigits.contains(lastDigit);
      }
      const bucaMap = {
        DateTime.monday: [1, 2],
        DateTime.tuesday: [3, 4],
        DateTime.wednesday: [5, 6],
        DateTime.thursday: [7, 8],
        DateTime.friday: [9, 0],
      };
      return (bucaMap[wd] ?? const []).contains(lastDigit);
    }

    // Resto de ciudades intermedias con esquema estándar L-V
    const genericMap = {
      DateTime.monday: [1, 2],
      DateTime.tuesday: [3, 4],
      DateTime.wednesday: [5, 6],
      DateTime.thursday: [7, 8],
      DateTime.friday: [9, 0],
    };
    return (genericMap[wd] ?? const []).contains(lastDigit);
  }

  static String _normalizeCity(String raw) {
    return raw
        .toUpperCase()
        .replaceAll('Á', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ú', 'U')
        .trim();
  }

  Future<void> _scheduleNightAndMorningReminders({
    required String plate,
    required bool isCar,
    required String cityName,
  }) async {
    if (plate.trim().isEmpty) return;
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowStatus = evaluateForDate(
      plate: plate,
      isCar: isCar,
      cityName: cityName,
      date: tomorrow,
    );

    if (!tomorrowStatus.hasRestrictionSystem ||
        !tomorrowStatus.appliesToVehicleType ||
        !tomorrowStatus.isRestrictedToday) {
      return;
    }

    final tonight = DateTime(now.year, now.month, now.day, 20, 0);
    if (tonight.isAfter(now)) {
      await NotificationService().showMaintenanceNotification(
        id: 8801,
        title: 'Aviso Pico y Placa Mañana ($cityName)',
        body: 'Recuerda: mañana tu placa $plate tiene Pico y Placa (${tomorrowStatus.scheduleText}).',
        scheduledDate: tonight,
      );
    }

    final morning = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 5, 30);
    await NotificationService().showMaintenanceNotification(
      id: 8802,
      title: 'HOY PICO Y PLACA en $cityName',
      body: 'Tu placa $plate tiene restricción hoy (${tomorrowStatus.scheduleText}). Evita la multa C14.',
      scheduledDate: morning,
    );
  }
}
