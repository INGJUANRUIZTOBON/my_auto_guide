-- =============================================================================
-- ota_v1_2_6_gps_waze_license.sql — Publicación OTA v1.2.6+23
-- =============================================================================
-- Nota: Si aún no ejecutaste `mega_lanzamiento_v1_2_0.sql`, ejecútalo primero.

INSERT INTO public.app_versions (
    version_code,
    version_name,
    zip_url,
    release_notes,
    is_mandatory,
    min_supported_version
)
VALUES (
    23,
    '1.2.6',
    'https://github.com/INGJUANRUIZTOBON/my_auto_guide/releases/download/1.1.0/app-release.apk',
    '• Corrección GPS Recorrido Libre y Navegación estilo Waze: stream continuo de alta frecuencia en primer plano con filtro Kalman, Road Snapping sobre la ruta, interpolación fluida a 60fps del marcador, rotación por rumbo (Modo Brújula Waze / Norte fijo) y zoom adaptativo por velocidad.\n• Resiliencia real en segundo plano con pantalla suspendida (promoción inmediata a Foreground Service Android sin conflictos).\n• Extracción inteligente de Licencias RUNTPRO en 3 etapas (expansión automática de acordeones + polling "Ver Detalle" + soporte tarjetas móviles apiladas sin confusión entre fecha de expedición y vencimiento).',
    true,
    1
)
ON CONFLICT (version_code) DO UPDATE
SET
    version_name = EXCLUDED.version_name,
    zip_url = EXCLUDED.zip_url,
    release_notes = EXCLUDED.release_notes,
    is_mandatory = EXCLUDED.is_mandatory,
    min_supported_version = EXCLUDED.min_supported_version;
