-- =============================================================================
-- publish_v1_1_0_build15.sql — PUBLICACIÓN DE ACTUALIZACIÓN OTA v1.1.0+15
-- =============================================================================
-- Ejecutar en Supabase Dashboard -> SQL Editor cuando subas el APK al Release.

INSERT INTO public.app_versions (
    version_code,
    version_name,
    zip_url,
    release_notes,
    is_mandatory,
    min_supported_version
)
VALUES (
    15,
    '1.1.0',
    'https://github.com/INGJUANRUIZTOBON/my_auto_guide/releases/download/1.1.0/app-release.apk',
    '• Master Mechanic IA reparado con Gemini 2.5 Flash y análisis de fotos (Cámara y Galería).\n• Cambio de contraseña directo desde Supabase (enlace de correo y botón dentro de la app).\n• Notificaciones (SnackBar) corregidas en modo oscuro con alto contraste.\n• Confirmación de correo con diseño My Auto Guide y retorno automático a la app.',
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
