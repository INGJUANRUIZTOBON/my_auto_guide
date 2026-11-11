import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Detecta automáticamente si el dispositivo Bluetooth vinculado al carro o casco
/// está activo para sugerir o iniciar la grabación de ruta sin intervención manual.
class AutoBluetoothTripService {
  static final AutoBluetoothTripService _instance = AutoBluetoothTripService._internal();
  factory AutoBluetoothTripService() => _instance;
  AutoBluetoothTripService._internal();

  static String _deviceNameKey(String vehiculoId) => 'auto_bt_device_$vehiculoId';
  static String _enabledKey(String vehiculoId) => 'auto_bt_enabled_$vehiculoId';

  Future<({bool enabled, String deviceName})> getConfig(String vehiculoId) async {
    final prefs = await SharedPreferences.getInstance();
    return (
      enabled: prefs.getBool(_enabledKey(vehiculoId)) ?? false,
      deviceName: prefs.getString(_deviceNameKey(vehiculoId)) ?? '',
    );
  }

  Future<void> saveConfig({
    required String vehiculoId,
    required bool enabled,
    required String deviceName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey(vehiculoId), enabled);
    await prefs.setString(_deviceNameKey(vehiculoId), deviceName.trim());
  }

  /// Verifica dispositivos BLE/Bluetooth conectados actualmente que coincidan con el vehículo.
  Future<bool> isTargetDeviceConnected(String vehiculoId) async {
    final cfg = await getConfig(vehiculoId);
    if (!cfg.enabled || cfg.deviceName.isEmpty) return false;
    final target = cfg.deviceName.toLowerCase();

    try {
      final connected = FlutterBluePlus.connectedDevices;
      for (final d in connected) {
        if (d.platformName.toLowerCase().contains(target)) {
          return true;
        }
      }
      final bonded = await FlutterBluePlus.bondedDevices;
      for (final d in bonded) {
        if (d.platformName.toLowerCase().contains(target) && d.isConnected) {
          return true;
        }
      }
    } catch (e) {
      debugPrint('[AUTO_BT] No se pudo verificar Bluetooth: $e');
    }
    return false;
  }
}
