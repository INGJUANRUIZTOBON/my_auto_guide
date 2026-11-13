import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../navigation/logic/map_tile_config.dart';
import '../../../../shared/widgets/smart_vehicle_image.dart';

/// Pantalla de Telemetría GPS en Vivo (Web y Móvil)
/// Permite monitorear la ubicación en tiempo real del vehículo cuando el teléfono
/// está en ruta, transmitida vía Supabase Realtime WebSockets.
class LiveTelemetryScreen extends StatefulWidget {
  final String vehicleId;
  final String placa;
  final String marca;
  final String modelo;
  final String? imagePath;

  const LiveTelemetryScreen({
    super.key,
    required this.vehicleId,
    required this.placa,
    required this.marca,
    required this.modelo,
    this.imagePath,
  });

  @override
  State<LiveTelemetryScreen> createState() => _LiveTelemetryScreenState();
}

class _LiveTelemetryScreenState extends State<LiveTelemetryScreen> {
  final MapController _mapController = MapController();
  final supabase = Supabase.instance.client;

  RealtimeChannel? _trackingChannel;
  LatLng _currentLocation = const LatLng(6.2442, -75.5812); // Medellín por defecto
  double _currentSpeed = 0.0;
  double _distanceTraveled = 0.0;
  double _heading = 0.0;
  DateTime? _lastPing;
  bool _isLive = false;
  bool _autoCenter = true;
  final List<LatLng> _liveTrail = [];

  @override
  void initState() {
    super.initState();
    _loadLastKnownPosition();
    _subscribeToLiveTracking();
  }

  @override
  void dispose() {
    _trackingChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadLastKnownPosition() async {
    try {
      final res = await supabase
          .from('routes')
          .select('via_puntos, distancia_km, created_at')
          .eq('vehicle_id', widget.vehicleId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (res != null && mounted) {
        final puntos = res['via_puntos'];
        if (puntos is List && puntos.isNotEmpty) {
          final first = puntos.last;
          if (first is Map && first['lat'] != null && first['lng'] != null) {
            setState(() {
              _currentLocation = LatLng(
                (first['lat'] as num).toDouble(),
                (first['lng'] as num).toDouble(),
              );
            });
            _mapController.move(_currentLocation, 15);
          }
        }
      }
    } catch (_) {}
  }

  void _subscribeToLiveTracking() {
    final channelName = 'tracking:${widget.vehicleId}';
    _trackingChannel = supabase.channel(channelName);

    // Escuchar broadcast directo desde el teléfono en ruta
    _trackingChannel!.onBroadcast(
      event: 'location_update',
      callback: (payload) {
        if (!mounted) return;
        final lat = (payload['lat'] as num?)?.toDouble();
        final lng = (payload['lng'] as num?)?.toDouble();
        final spd = (payload['speed'] as num?)?.toDouble() ?? 0.0;
        final dst = (payload['dist'] as num?)?.toDouble() ?? 0.0;
        final hdg = (payload['heading'] as num?)?.toDouble() ?? 0.0;

        if (lat != null && lng != null) {
          final newPos = LatLng(lat, lng);
          setState(() {
            _currentLocation = newPos;
            _currentSpeed = spd;
            _distanceTraveled = dst;
            _heading = hdg;
            _lastPing = DateTime.now();
            _isLive = true;
            _liveTrail.add(newPos);
            if (_liveTrail.length > 500) {
              _liveTrail.removeAt(0);
            }
          });

          if (_autoCenter) {
            _mapController.move(newPos, _mapController.camera.zoom);
          }
        }
      },
    );

    // Escuchar estado de presencia para detectar si el celular está en ruta activa
    _trackingChannel!.onPresenceSync((_) {
      if (!mounted) return;
      final presenceState = _trackingChannel!.presenceState();
      final isOnline = presenceState.isNotEmpty;
      setState(() {
        _isLive = isOnline;
      });
    });

    _trackingChannel!.subscribe();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _isLive
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                    : Colors.white10,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isLive ? const Color(0xFF00E5FF) : Colors.white24,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isLive
                          ? const Color(0xFF00E5FF)
                          : const Color(0xFFFFA000),
                      boxShadow: _isLive
                          ? [
                              const BoxShadow(
                                color: Color(0xFF00E5FF),
                                blurRadius: 6,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isLive ? 'EN VIVO' : 'ESTACIONADO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: _isLive
                          ? const Color(0xFF00E5FF)
                          : const Color(0xFFFFA000),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${widget.placa.toUpperCase()} — ${widget.marca} ${widget.modelo}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Centrar en vehículo',
            icon: Icon(
              Icons.my_location_rounded,
              color: _autoCenter ? const Color(0xFF00E5FF) : Colors.white60,
            ),
            onPressed: () {
              setState(() => _autoCenter = !_autoCenter);
              _mapController.move(_currentLocation, 16);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // 1. Mapa Leaflet / OpenStreetMap interactivo
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 15,
              onPositionChanged: (_, hasGesture) {
                if (hasGesture && _autoCenter) {
                  setState(() => _autoCenter = false);
                }
              },
            ),
            children: [
              MapTileConfig.buildTileLayer(style: MapStyle.dark),
              // Rastro recorrido en vivo
              if (_liveTrail.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _liveTrail,
                      strokeWidth: 4,
                      color: const Color(0xFF00E5FF),
                    ),
                  ],
                ),
              // Marcador del vehículo
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation,
                    width: 64,
                    height: 64,
                    child: Transform.rotate(
                      angle: (_heading * (3.141592653589793 / 180.0)),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                              border: Border.all(
                                color: const Color(0xFF00E5FF),
                                width: 2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0xFF00E5FF),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.navigation_rounded,
                            size: 32,
                            color: Color(0xFF00E5FF),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. HUD Flotante con métricas en tiempo real
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _buildMetricCard(
                  label: 'VELOCIDAD',
                  value: '${_currentSpeed.toStringAsFixed(0)} km/h',
                  icon: Icons.speed_rounded,
                  accentColor: const Color(0xFF00E5FF),
                ),
                const SizedBox(width: 12),
                _buildMetricCard(
                  label: 'DISTANCIA',
                  value: '${_distanceTraveled.toStringAsFixed(2)} km',
                  icon: Icons.alt_route_rounded,
                  accentColor: const Color(0xFF30D158),
                ),
                const SizedBox(width: 12),
                _buildMetricCard(
                  label: 'ACTUALIZACIÓN',
                  value: _lastPing != null
                      ? '${DateTime.now().difference(_lastPing!).inSeconds}s'
                      : 'N/A',
                  icon: Icons.sync_rounded,
                  accentColor: const Color(0xFFFFD60A),
                ),
              ],
            ),
          ),

          // 3. Tarjeta informativa inferior
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: SmartVehicleImage(
                      imagePath: widget.imagePath,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${widget.marca} ${widget.modelo}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _isLive
                              ? 'Transmitiendo posición GPS vía teléfono móvil en ruta'
                              : 'Esperando que el conductor inicie recorrido en la app móvil',
                          style: TextStyle(
                            color: _isLive
                                ? const Color(0xFF00E5FF)
                                : Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: accentColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                      color: Colors.white54,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
