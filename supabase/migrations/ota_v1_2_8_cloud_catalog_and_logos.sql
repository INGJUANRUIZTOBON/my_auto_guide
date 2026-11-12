-- =============================================================================
-- ota_v1_2_8_cloud_catalog_and_logos.sql — Publicación OTA v1.2.8+25
-- =============================================================================
-- Registra la actualización OTA v1.2.8 con:
-- 1. Logos de marcas corregidos y enlazados limpiamente al CDN de Supabase Storage.
-- 2. 27 nuevos modelos colombianos añadidos al catálogo Cloud (127 modelos en total).
-- 3. Normalización robusta de marcas comerciales (AKT, Hero, Royal Enfield, etc.).
-- 4. Soporte de imágenes sin fondo cargadas desde la nube para optimizar peso del APK.

INSERT INTO public.app_versions (
    version_code,
    version_name,
    zip_url,
    release_notes,
    is_mandatory,
    min_supported_version
)
VALUES (
    25,
    '1.2.8',
    'https://github.com/INGJUANRUIZTOBON/my_auto_guide/releases/download/1.1.0/app-release.apk',
    '• Logos oficiales de marcas corregidos: visualización transparente HD en la barra de selección tanto de carros como de motos.
• 27 nuevos modelos colombianos integrados al catálogo Cloud (127 modelos en total: BWS 125, Aerox 155, Seltos, CR4 150/200, Gixxer 250, Montana, Silverado, etc.).
• Optimización de peso de la APK y CDN Cloud: Las imágenes se cargan dinámicamente desde Supabase Storage CDN con caché local sin aumentar el tamaño de descarga.
• Resiliencia y auto-actualización OTA mejorada con GitHub Releases y Supabase.',
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
