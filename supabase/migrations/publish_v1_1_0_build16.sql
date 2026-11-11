-- =============================================================================
-- publish_v1_1_0_build16.sql — COLUMNAS RUNT + PUBLICACIÓN OTA v1.1.0+16
-- =============================================================================
-- Ejecutar en Supabase Dashboard -> SQL Editor.

ALTER TABLE public.vehiculos
    ADD COLUMN IF NOT EXISTS runt_data JSONB DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS runt_last_check TIMESTAMPTZ DEFAULT NULL;

INSERT INTO public.app_versions (
    version_code,
    version_name,
    zip_url,
    release_notes,
    is_mandatory,
    min_supported_version
)
VALUES (
    16,
    '1.1.0',
    'https://github.com/INGJUANRUIZTOBON/my_auto_guide/releases/download/1.1.0/app-release.apk',
    '• Mapa GPS corregido sin marcas de agua "API KEY REQUIRED" con selector Calle / Oscuro / Satélite.\n• Grabación de ruta curva a curva con celular suspendido (WakeLock + persistencia local en segundo plano).\n• Guía de permisos de ubicación Todo el Tiempo y exención de batería.\n• Extracción y visualización de ficha técnica completa desde RUNT oficial (SOAT, RTM, VIN, motor, gravámenes).',
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
