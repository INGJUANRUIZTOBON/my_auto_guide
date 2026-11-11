-- =============================================================================
-- ota_v1_2_2_brand_runt.sql — Publicación OTA v1.2.2+19
-- =============================================================================
-- Nota: Si aún no ejecutaste `mega_lanzamiento_v1_2_0.sql` (las 6 tablas nuevas),
-- ejecútalo primero en Supabase -> SQL Editor y luego pega este script.

INSERT INTO public.app_versions (
    version_code,
    version_name,
    zip_url,
    release_notes,
    is_mandatory,
    min_supported_version
)
VALUES (
    19,
    '1.2.2',
    'https://github.com/INGJUANRUIZTOBON/my_auto_guide/releases/download/1.1.0/app-release.apk',
    '• Nueva identidad de marca MY AUTO GUIDE con ícono launcher y pantalla de inicio renovada ("Tu vehículo, bajo control inteligente").\n• Corrección completa del extractor RUNTPRO (Angular Material) para leer marca, línea, clase, SOAT y Tecnomecánica correctamente.\n• Incluye animación cinemática de arranque, Pico y Placa GPS, Modo Conductor, Mi Flota PESV, Navegación Pro y OBD2 HUD.',
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
