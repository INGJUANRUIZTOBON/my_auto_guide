-- =============================================================================
-- ota_v1_2_9_hologram_laser_loader.sql — Publicación OTA v1.2.9+26
-- =============================================================================
-- Registra la actualización OTA v1.2.9 con:
-- 1. Animación cinemática de carga con Escaneo Láser Holográfico a 60-120 FPS.
-- 2. Túnel de viento aerodinámico adaptativo sobre siluetas vectoriales de Carro y Moto.
-- 3. Micro-shimmer acelerado por GPU para logos y miniaturas (<=80px).
-- 4. Cross-fade suave de 250ms con micro-escala natural (0.96 -> 1.0) al revelar la foto.
-- 5. Manejo inteligente de modo offline y timeout con botón discreto de reintento.
-- 6. Respuesta háptica sutil en el vehículo principal del garaje.

INSERT INTO public.app_versions (
    version_code,
    version_name,
    zip_url,
    release_notes,
    is_mandatory,
    min_supported_version
)
VALUES (
    26,
    '1.2.9',
    'https://github.com/INGJUANRUIZTOBON/my_auto_guide/releases/download/1.1.0/app-release.apk',
    '• Nueva Animación de Carga Cinemática: Escaneo Láser Holográfico a 60-120 FPS sobre siluetas aerodinámicas nativas de carro y moto con efecto túnel de viento.
• Micro-Shimmer Adaptativo: Carga fluida y liviana para logos de marcas y miniaturas sin sobrecargar la GPU.
• Transición de Revelado Suave: Cross-fade de 250ms con micro-escala natural y respuesta háptica sutil al finalizar la descarga.
• Resiliencia Offline: Timeout inteligente de 5s con opción de reintento si estás en carretera sin cobertura 4G.
• Cero impacto en batería: Renderizado 100% vectorial acelerado por hardware sin rebuilds innecesarios.',
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
