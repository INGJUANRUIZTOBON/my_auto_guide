import json

with open('scripts/motai_processed_final.json', 'r', encoding='utf-8') as f:
    motos = json.load(f)

sql_lines = []
sql_lines.append("-- =============================================================================")
sql_lines.append("-- 20261112_add_motai_motorcycles_catalog.sql — CATÁLOGO EXPANDIDO DE MOTOS (MOTAI)")
sql_lines.append("-- =============================================================================")
sql_lines.append("-- Integra 62 modelos nuevos y 4 marcas oficiales con siluetas transparentes HD")
sql_lines.append("-- almacenadas en Supabase Storage (catalog-assets).")
sql_lines.append("")

# 1. New Brands
new_brands = [
    ('benelli', 'Benelli', 'moto', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/benelli.png', '#005C30', 'Italia', 75),
    ('fratelli', 'Fratelli', 'moto', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/fratelli.png', '#C41230', 'Colombia', 60),
    ('kymco', 'Kymco', 'moto', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/kymco.png', '#E60012', 'Taiwán', 78),
    ('sym', 'SYM', 'moto', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/sym.png', '#005BAC', 'Taiwán', 70),
    ('royal_enfield', 'Royal Enfield', 'moto', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/royal_enfield.png', '#8B1E1E', 'India', 82),
]

sql_lines.append("-- 1. REGISTRO / ACTUALIZACIÓN DE MARCAS OFICIALES DE MOTOS")
sql_lines.append("INSERT INTO public.catalogo_marcas (id, nombre, tipo, logo_url, color_hex, pais_origen, popularidad, activo)")
sql_lines.append("VALUES")

brand_vals = []
for bid, name, tipo, logo, color, country, pop in new_brands:
    brand_vals.append(f"  ('{bid}', '{name}', '{tipo}', '{logo}', '{color}', '{country}', {pop}, true)")
sql_lines.append(",\n".join(brand_vals))
sql_lines.append("ON CONFLICT (id) DO UPDATE SET")
sql_lines.append("  logo_url = EXCLUDED.logo_url,")
sql_lines.append("  color_hex = EXCLUDED.color_hex,")
sql_lines.append("  activo = EXCLUDED.activo;")
sql_lines.append("")

# 2. Unique Constraint
sql_lines.append("-- 2. GARANTIZAR RESTRICCIÓN ÚNICA PARA EVITAR DUPLICADOS")
sql_lines.append("CREATE UNIQUE INDEX IF NOT EXISTS idx_catalogo_modelos_unique_marca_linea_modelo")
sql_lines.append("  ON public.catalogo_modelos(marca_id, tipo, modelo);")
sql_lines.append("")

# 3. Models
sql_lines.append("-- 3. INSERCIÓN DE 62 MODELOS NUEVOS DE MOTOS (MOTAI)")
sql_lines.append("INSERT INTO public.catalogo_modelos (")
sql_lines.append("  marca_id, tipo, linea, modelo, anio_inicio, cilindraje_cc, tipo_combustible,")
sql_lines.append("  capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo")
sql_lines.append(")")
sql_lines.append("VALUES")

model_vals = []
for m in motos:
    b_slug = m['marca_slug']
    tipo = 'moto'
    linea = m['linea'].replace("'", "''")
    modelo = m['modelo'].replace("'", "''")
    ano = m['ano']
    cc = m['cc']
    combustible = 'Gasolina'
    tanque = 3.0
    hp = 0.0
    aceite = '20W-50 Semisintético'
    img = m['cdn_url']
    pop = 80
    
    model_vals.append(
        f"  ('{b_slug}', '{tipo}', '{linea}', '{modelo}', {ano}, {cc}, '{combustible}', {tanque}, {hp}, '{aceite}', '{img}', {pop}, true)"
    )

sql_lines.append(",\n".join(model_vals))
sql_lines.append("ON CONFLICT (marca_id, tipo, modelo) DO UPDATE SET")
sql_lines.append("  imagen_url = EXCLUDED.imagen_url,")
sql_lines.append("  cilindraje_cc = EXCLUDED.cilindraje_cc,")
sql_lines.append("  anio_inicio = EXCLUDED.anio_inicio,")
sql_lines.append("  activo = EXCLUDED.activo;")
sql_lines.append("")

# 4. App version OTA
sql_lines.append("-- 4. REGISTRO OFICIAL DE ACTUALIZACIÓN OVER-THE-AIR (OTA) v1.2.13 BUILD 31")
sql_lines.append("INSERT INTO public.app_versions (")
sql_lines.append("  version_code, version_name, zip_url, release_notes, is_mandatory, min_supported_version")
sql_lines.append(")")
sql_lines.append("VALUES (")
sql_lines.append("  31,")
sql_lines.append("  '1.2.13',")
sql_lines.append("  'https://github.com/INGJUANRUIZTOBON/my_auto_guide/releases/download/1.1.0/app-release.apk',")
sql_lines.append("  '• Catálogo Motos Motai HD: 62 nuevos modelos de motocicletas con siluetas transparentes de alta resolución sin fondo.\\n• 4 Nuevas Marcas Oficiales de Motos: Benelli, Kymco, SYM y Fratelli con logos vectorizados HD.\\n• Catálogo Expandido de Motos: Nuevas líneas icónicas de Victory (Combat, MRX, Nitro, One ST), TVS (Sport 110, Neo), Hero (Hunk 160 4V, XPulse 200, Eco 100), AKT (AK200DS, Sc-r), Honda, Bajaj y Royal Enfield (Hntr 350).\\n• Cero Peso Extra en el APK: 100% de siluetas de motos servidas dinámicamente desde el CDN de Supabase Storage.\\n• Resiliencia Offline Completa: Mapeo de logos y colores oficiales para todas las marcas nuevas sin iconos rotos.',")
sql_lines.append("  true,")
sql_lines.append("  1")
sql_lines.append(")")
sql_lines.append("ON CONFLICT (version_code) DO UPDATE SET")
sql_lines.append("  version_name = EXCLUDED.version_name,")
sql_lines.append("  release_notes = EXCLUDED.release_notes,")
sql_lines.append("  is_mandatory = EXCLUDED.is_mandatory;")

out_file = 'supabase/migrations/20261112_add_motai_motorcycles_catalog.sql'
with open(out_file, 'w', encoding='utf-8') as f:
    f.write("\n".join(sql_lines))

print(f"Migración SQL generada con éxito en {out_file} ({len(motos)} modelos + marcas + version 31)")
