-- =============================================================================
-- ota_v1_2_7_cloud_catalog.sql — Publicación OTA v1.2.7+24
-- =============================================================================
-- Registra la actualización OTA v1.2.7 con el nuevo Catálogo de Vehículos Cloud
-- y Registro Manual con foto.
-- Requiere ejecutar previamente `create_vehicle_catalog.sql` en Supabase.

INSERT INTO public.app_versions (
    version_code,
    version_name,
    zip_url,
    release_notes,
    is_mandatory,
    min_supported_version
)
VALUES (
    24,
    '1.2.7',
    'https://github.com/INGJUANRUIZTOBON/my_auto_guide/releases/download/1.1.0/app-release.apk',
    '• Nueva API y Catálogo Cloud de Marcas y Modelos de Colombia: Carga dinámica bajo demanda desde Supabase PostgREST (sin engordar el APK) con logos y siluetas de alta definición transparentes.\n• Especificaciones técnicas completas integradas: cilindraje (cc), tipo de combustible, capacidad de tanque (galones), potencia (HP) y grado de aceite recomendado.\n• Modo Registro Manual de Vehículo: Permite escribir marca y modelo personalizado y adjuntar foto desde cámara o galería si tu vehículo no está en el catálogo.\n• SmartVehicleImage: Renderizador universal de imágenes con soporte para URLs remotas, almacenamiento local y bundle assets, con caché en memoria y siluetas SVG optimizadas.\n• Modo Offline-First: Caché persistente en SharedPreferences con semillas locales de emergencia para funcionamiento sin conexión.',
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
