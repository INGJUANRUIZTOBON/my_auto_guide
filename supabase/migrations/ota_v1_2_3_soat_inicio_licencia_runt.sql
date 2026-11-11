-- =============================================================================
-- ota_v1_2_3_soat_inicio_licencia_runt.sql — Publicación OTA v1.2.3+20
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
    20,
    '1.2.3',
    'https://github.com/INGJUANRUIZTOBON/my_auto_guide/releases/download/1.1.0/app-release.apk',
    '• Corrección SOAT y Tecnomecánica RUNT: ahora registra la fecha de inicio de vigencia / expedición y calcula el % real de vida útil restante sin falsos 100%.\n• Nuevo módulo Mi Licencia de Conducción RUNT (consulta ciudadana por cédula para ver tus categorías, cuáles están vigentes y cuándo vence cada una, con alertas automáticas).\n• Incluye toda la experiencia v1.2.x (nuevo logo MY AUTO GUIDE, arranque cinemático, Pico y Placa GPS, Modo Conductor y Mi Flota PESV).',
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
