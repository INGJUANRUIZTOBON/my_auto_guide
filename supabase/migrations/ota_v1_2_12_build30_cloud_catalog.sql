-- =============================================================================
-- ota_v1_2_12_build30_cloud_catalog.sql — Publicación OTA v1.2.12+30
-- =============================================================================
-- Registra la actualización OTA v1.2.12 (Build 30) en Supabase:
-- 1. Catálogo 100% Remoto en Supabase Storage CDN: 32 marcas y 87 modelos nuevos
--    con imágenes transparentes en alta definición servidas directamente desde la nube.
-- 2. Cero imágenes embebidas en el APK: Instalador ultraligero, rápido de descargar y actualizar.
-- 3. Animación Holográfica Láser a 60-120 FPS durante la descarga de fotos con micro-caché en memoria.
-- 4. Notificación y servicio GPS bajo demanda estricto para ahorro óptimo de batería.

INSERT INTO public.app_versions (
    version_code,
    version_name,
    zip_url,
    release_notes,
    is_mandatory,
    min_supported_version
)
VALUES (
    30,
    '1.2.12',
    'https://github.com/INGJUANRUIZTOBON/my_auto_guide/releases/download/1.1.0/app-release.apk',
    '• Catálogo 100% Remoto en CDN Supabase: 32 marcas y 87 modelos nuevos con siluetas transparentes HD servidas directamente desde la nube.
• Nuevas Marcas y Modelos: Deepal (S07), Audi (Q5, Q3), BMW (X2, X5), Chery (Tiggo 4, eQ7), Haval (H6), Jeep (Wrangler), Suzuki (Baleno, Fronx), Tesla (Model Y), VW (Golf), Changan, JMC, Opel y más.
• Instalador Ultraligero: Cero imágenes pesadas embebidas en el APK, permitiendo descargas e instalaciones inmediatas.
• Escaneo Láser Holográfico: Carga cinemática fluida a 60-120 FPS con caché inteligente en memoria sin consumir datos adicionales tras la primera vista.
• GPS Bajo Demanda: Máximo ahorro de batería con servicio satelital activo exclusivamente durante recorridos.',
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
