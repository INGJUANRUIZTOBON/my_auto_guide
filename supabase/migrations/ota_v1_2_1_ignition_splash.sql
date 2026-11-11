-- =============================================================================
-- ota_v1_2_1_ignition_splash.sql — Publicación OTA v1.2.1+18
-- =============================================================================
-- Nota: Si aún no has ejecutado `mega_lanzamiento_v1_2_0.sql`, ejecútalo primero
-- y luego pega este bloque (o simplemente actualiza version_code = 18).

INSERT INTO public.app_versions (
    version_code,
    version_name,
    zip_url,
    release_notes,
    is_mandatory,
    min_supported_version
)
VALUES (
    18,
    '1.2.1',
    'https://github.com/INGJUANRUIZTOBON/my_auto_guide/releases/download/1.1.0/app-release.apk',
    '• Nueva animación cinemática de arranque automotriz (ignición de faros LED, barrido real de tacómetro a ralentí, escaneo volumétrico, vibración háptica y checklist Colombia).\n• Identidad del vehículo en caché (Carro/Moto + foto/placa) y opción de tocar para entrar apenas carguen los datos.\n• Incluye todas las novedades de v1.2.0 (Pico y Placa GPS, Modo Conductor, Mi Flota PESV, Navegación Pro y OBD2 HUD).',
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
