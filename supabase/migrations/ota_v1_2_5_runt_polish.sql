-- =============================================================================
-- ota_v1_2_5_runt_polish.sql — Publicación OTA v1.2.5+22
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
    22,
    '1.2.5',
    'https://github.com/INGJUANRUIZTOBON/my_auto_guide/releases/download/1.1.0/app-release.apk',
    '• Nueva Ficha Técnica RUNT con diseño Obsidiana Cockpit (sin textos de íconos internos, tarjetas SOAT/Tecnomecánica y especificaciones limpias).\n• Corrección automática de Licencias RUNT: evita inyectar hashes SHA-256 en cédula, abre automáticamente "Ver Detalle" y detecta correctamente categorías vigentes (ej. A2/B1 vs C1 vencida).\n• Pantalla de Actualización Disponible rediseñada con la identidad oficial MY AUTO GUIDE.',
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
