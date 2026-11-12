-- =============================================================================
-- ota_v1_2_10_gps_on_demand_only.sql — Publicación OTA v1.2.10+27
-- =============================================================================
-- Registra la actualización OTA v1.2.10 con:
-- 1. Notificación persistente y Foreground Service de GPS estrictamente bajo demanda:
--    SOLO se activa al presionar "Iniciar Ruta" o "Recorrido Libre" en la pantalla de Navegación.
-- 2. Destrucción automática y eliminación inmediata de la notificación al finalizar la ruta,
--    al presionar salir de la pantalla de Rutas (dispose) o al arrancar la app.
-- 3. Limpieza de procesos huérfanos en segundo plano para ahorro total de batería.

INSERT INTO public.app_versions (
    version_code,
    version_name,
    zip_url,
    release_notes,
    is_mandatory,
    min_supported_version
)
VALUES (
    27,
    '1.2.10',
    'https://github.com/INGJUANRUIZTOBON/my_auto_guide/releases/download/1.1.0/app-release.apk',
    '• Notificación GPS estrictamente bajo demanda: La notificación fija "Recorrido en Progreso" SOLO aparece cuando inicias activamente un viaje en Rutas/Navegación. Nunca más visible en reposo, en el garaje o al abrir la app.
• Auto-destrucción y limpieza inmediata: Al tocar "Finalizar Recorrido" o salir del mapa, el servicio se detiene y la notificación desaparece al instante de la barra de estado.
• Máximo ahorro de batería: El chip GPS no consume energía cuando no estás en un viaje activo.',
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
