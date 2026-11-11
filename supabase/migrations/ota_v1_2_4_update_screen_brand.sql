-- =============================================================================
-- ota_v1_2_4_update_screen_brand.sql — Publicación OTA v1.2.4+21
-- =============================================================================
-- Nota: Si aún no ejecutaste `mega_lanzamiento_v1_2_0.sql` (tablas y columnas nuevas),
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
    21,
    '1.2.4',
    'https://github.com/INGJUANRUIZTOBON/my_auto_guide/releases/download/1.1.0/app-release.apk',
    '• Nueva pantalla de Actualización Disponible rediseñada con la identidad oficial MY AUTO GUIDE (Obsidiana Cockpit, logo oficial y eslogan).\n• Incluye corrección de vigencia SOAT/Tecnomecánica RUNT, módulo Mi Licencia RUNT, nuevo ícono, arranque cinemático, Pico y Placa GPS, Modo Conductor y Mi Flota PESV.',
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
