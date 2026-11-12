import json

def escape_sql(text):
    if text is None:
        return ''
    return str(text).replace("'", "''")

# Cargar Autoland (52) y Autonal (35)
with open('scripts/autoland_processed_final.json', 'r', encoding='utf-8') as f:
    autoland = json.load(f)

with open('scripts/autonal_processed_final.json', 'r', encoding='utf-8') as f:
    autonal = json.load(f)

print(f"Modelos Autoland: {len(autoland)}")
print(f"Modelos Autonal: {len(autonal)}")

# Marcas unificadas
brands_dict = {
    'audi': {'nombre': 'Audi', 'tipo': 'carro', 'logo': 'assets/logos/audi_logo.png', 'color': '#BB0A30', 'pais': 'Alemania', 'pop': 84},
    'bmw': {'nombre': 'BMW', 'tipo': 'ambos', 'logo': 'assets/logos/bmw_logo.png', 'color': '#0066B1', 'pais': 'Alemania', 'pop': 88},
    'byd': {'nombre': 'BYD', 'tipo': 'carro', 'logo': 'assets/logos/byd_logo.png', 'color': '#E60012', 'pais': 'China', 'pop': 85},
    'changan': {'nombre': 'Changan', 'tipo': 'carro', 'logo': 'assets/logos/changan.png', 'color': '#003882', 'pais': 'China', 'pop': 76},
    'chery': {'nombre': 'Chery', 'tipo': 'carro', 'logo': 'assets/logos/chery.png', 'color': '#B01116', 'pais': 'China', 'pop': 75},
    'chevrolet': {'nombre': 'Chevrolet', 'tipo': 'carro', 'logo': 'assets/logos/chevrolet_logo.png', 'color': '#CD9834', 'pais': 'Estados Unidos', 'pop': 92},
    'citroen': {'nombre': 'Citroën', 'tipo': 'carro', 'logo': 'assets/logos/citroen.png', 'color': '#6E1D24', 'pais': 'Francia', 'pop': 75},
    'cupra': {'nombre': 'Cupra', 'tipo': 'carro', 'logo': 'assets/logos/cupra.png', 'color': '#BE5E2A', 'pais': 'España', 'pop': 79},
    'deepal': {'nombre': 'Deepal', 'tipo': 'carro', 'logo': 'assets/logos/deepal.png', 'color': '#007A87', 'pais': 'China', 'pop': 74},
    'ford': {'nombre': 'Ford', 'tipo': 'carro', 'logo': 'assets/logos/ford_logo.png', 'color': '#002C6C', 'pais': 'Estados Unidos', 'pop': 89},
    'haval': {'nombre': 'Haval', 'tipo': 'carro', 'logo': 'assets/logos/haval.png', 'color': '#D6001C', 'pais': 'China', 'pop': 73},
    'honda': {'nombre': 'Honda', 'tipo': 'ambos', 'logo': 'assets/logos/honda_logo.png', 'color': '#CC0000', 'pais': 'Japón', 'pop': 90},
    'hyundai': {'nombre': 'Hyundai', 'tipo': 'carro', 'logo': 'assets/logos/hyundai_logo.png', 'color': '#002C5F', 'pais': 'Corea del Sur', 'pop': 87},
    'jeep': {'nombre': 'Jeep', 'tipo': 'carro', 'logo': 'assets/logos/jeep_logo.png', 'color': '#FFC80A', 'pais': 'Estados Unidos', 'pop': 81},
    'jetour': {'nombre': 'Jetour', 'tipo': 'carro', 'logo': 'assets/logos/jetour.png', 'color': '#1E395B', 'pais': 'China', 'pop': 72},
    'jmc': {'nombre': 'JMC', 'tipo': 'carro', 'logo': 'assets/logos/jmc.png', 'color': '#D32F2F', 'pais': 'China', 'pop': 70},
    'kia': {'nombre': 'Kia', 'tipo': 'carro', 'logo': 'assets/logos/kia_logo.png', 'color': '#05141F', 'pais': 'Corea del Sur', 'pop': 91},
    'mazda': {'nombre': 'Mazda', 'tipo': 'carro', 'logo': 'assets/logos/mazda_logo.png', 'color': '#1B365D', 'pais': 'Japón', 'pop': 93},
    'mercedes_benz': {'nombre': 'Mercedes-Benz', 'tipo': 'carro', 'logo': 'assets/logos/mercedes_logo.png', 'color': '#00ADEF', 'pais': 'Alemania', 'pop': 86},
    'mini': {'nombre': 'Mini', 'tipo': 'carro', 'logo': 'assets/logos/mini.png', 'color': '#1B1B1B', 'pais': 'Reino Unido', 'pop': 75},
    'mitsubishi': {'nombre': 'Mitsubishi', 'tipo': 'carro', 'logo': 'assets/logos/mitsubishi_logo.png', 'color': '#E60012', 'pais': 'Japón', 'pop': 77},
    'nissan': {'nombre': 'Nissan', 'tipo': 'carro', 'logo': 'assets/logos/nissan_logo.png', 'color': '#C3002F', 'pais': 'Japón', 'pop': 90},
    'opel': {'nombre': 'Opel', 'tipo': 'carro', 'logo': 'assets/logos/opel.png', 'color': '#FFD500', 'pais': 'Alemania', 'pop': 71},
    'peugeot': {'nombre': 'Peugeot', 'tipo': 'carro', 'logo': 'assets/logos/peugeot_logo.png', 'color': '#002663', 'pais': 'Francia', 'pop': 78},
    'renault': {'nombre': 'Renault', 'tipo': 'carro', 'logo': 'assets/logos/renault_logo.png', 'color': '#FFCC00', 'pais': 'Francia', 'pop': 95},
    'seat': {'nombre': 'Seat', 'tipo': 'carro', 'logo': 'assets/logos/seat.png', 'color': '#D50000', 'pais': 'España', 'pop': 74},
    'subaru': {'nombre': 'Subaru', 'tipo': 'carro', 'logo': 'assets/logos/subaru.png', 'color': '#013C74', 'pais': 'Japón', 'pop': 79},
    'suzuki': {'nombre': 'Suzuki', 'tipo': 'ambos', 'logo': 'assets/logos/suzuki_logo.png', 'color': '#E30613', 'pais': 'Japón', 'pop': 89},
    'tesla': {'nombre': 'Tesla', 'tipo': 'carro', 'logo': 'assets/logos/tesla.png', 'color': '#E82127', 'pais': 'Estados Unidos', 'pop': 82},
    'toyota': {'nombre': 'Toyota', 'tipo': 'carro', 'logo': 'assets/logos/toyota_logo.png', 'color': '#EB0A1E', 'pais': 'Japón', 'pop': 96},
    'volkswagen': {'nombre': 'Volkswagen', 'tipo': 'carro', 'logo': 'assets/logos/volkswagen_logo.png', 'color': '#001E50', 'pais': 'Alemania', 'pop': 90},
    'volvo': {'nombre': 'Volvo', 'tipo': 'carro', 'logo': 'assets/logos/volvo.png', 'color': '#003057', 'pais': 'Suecia', 'pop': 83}
}

sql_lines = []
sql_lines.append("-- =============================================================================")
sql_lines.append("-- MIGRACIÓN UNIFICADA DE CATÁLOGO NACIONAL (AUTOLAND + AUTONAL COLOMBIA)")
sql_lines.append("-- Versión: 1.2.12 (Build 29)")
sql_lines.append("-- Soluciona ERROR 42P10 mediante deduplicación previa y creación de índice único")
sql_lines.append("-- =============================================================================\n")

sql_lines.append("-- PASO 1: CORRECCIÓN ESTRUCTURAL DE RESTRICCIÓN ÚNICA (Previene error 42P10)")
sql_lines.append("DELETE FROM public.catalogo_modelos a USING public.catalogo_modelos b")
sql_lines.append("WHERE a.id < b.id")
sql_lines.append("  AND a.marca_id = b.marca_id")
sql_lines.append("  AND a.tipo = b.tipo")
sql_lines.append("  AND a.linea = b.linea;\n")

sql_lines.append("CREATE UNIQUE INDEX IF NOT EXISTS idx_catalogo_modelos_unique_linea")
sql_lines.append("ON public.catalogo_modelos (marca_id, tipo, linea);\n")

sql_lines.append("CREATE UNIQUE INDEX IF NOT EXISTS idx_catalogo_marcas_id")
sql_lines.append("ON public.catalogo_marcas (id);\n")

sql_lines.append("-- PASO 2: REGISTRO Y ACTUALIZACIÓN DE MARCAS AUTOMOTRICES (32 Marcas)")
sql_lines.append("INSERT INTO public.catalogo_marcas (id, nombre, tipo, logo_url, color_hex, pais_origen, popularidad, activo)")
sql_lines.append("VALUES")

brand_rows = []
for bid, binfo in sorted(brands_dict.items()):
    logo_cdn = f"https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/{binfo['logo']}"
    brand_rows.append(f"  ('{bid}', '{escape_sql(binfo['nombre'])}', '{binfo['tipo']}', '{logo_cdn}', '{binfo['color']}', '{escape_sql(binfo['pais'])}', {binfo['pop']}, true)")

sql_lines.append(",\n".join(brand_rows))
sql_lines.append("ON CONFLICT (id) DO UPDATE SET")
sql_lines.append("  nombre = EXCLUDED.nombre,")
sql_lines.append("  tipo = EXCLUDED.tipo,")
sql_lines.append("  logo_url = EXCLUDED.logo_url,")
sql_lines.append("  color_hex = EXCLUDED.color_hex,")
sql_lines.append("  popularidad = GREATEST(catalogo_marcas.popularidad, EXCLUDED.popularidad),")
sql_lines.append("  activo = true;\n")

sql_lines.append("-- PASO 3: REGISTRO DE TODOS LOS MODELOS (AUTOLAND + AUTONAL)")
sql_lines.append("INSERT INTO public.catalogo_modelos (marca_id, tipo, linea, modelo, anio_inicio, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)")
sql_lines.append("VALUES")

seen_models = set()
model_rows = []

for m in autoland:
    marca_id = m['brand_id'].lower()
    tipo = 'carro'
    linea = m['linea']
    key = (marca_id, tipo, linea.lower())
    if key in seen_models:
        continue
    seen_models.add(key)
    
    modelo = m.get('modelo_completo', f"{marca_id.upper()} {linea}")
    specs = m.get('specs', {})
    anio = m.get('anio', 2023)
    cc = specs.get('cilindraje_cc', 1600)
    combustible = specs.get('tipo_combustible', 'Gasolina')
    gal = 14.5
    hp = specs.get('potencia_hp', 140)
    aceite = specs.get('aceite_recomendado', '5W-30 Sintético API SP')
    cdn = m.get('cdn_url')
    
    model_rows.append(
        f"  ('{marca_id}', '{tipo}', '{escape_sql(linea)}', '{escape_sql(modelo)}', {anio}, {cc}, '{escape_sql(combustible)}', {gal}, {hp}, '{escape_sql(aceite)}', '{cdn}', 85, true)"
    )

for m in autonal:
    marca_id = m.get('brand_slug', m.get('brand', '')).lower()
    tipo = 'carro'
    linea = m.get('line', '')
    key = (marca_id, tipo, linea.lower())
    if key in seen_models:
        continue
    seen_models.add(key)
    
    modelo = m.get('full_model', f"{marca_id.upper()} {linea}")
    specs = m.get('specs', {})
    anio = specs.get('year', 2023)
    cc = specs.get('cc', 1600)
    combustible = specs.get('fuel', 'Gasolina')
    gal = 14.5
    hp = specs.get('hp', 140)
    aceite = specs.get('oil', '5W-30 Sintético API SP')
    cdn = m.get('cdn_url') or f"https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/{m['asset_path']}"
    
    model_rows.append(
        f"  ('{marca_id}', '{tipo}', '{escape_sql(linea)}', '{escape_sql(modelo)}', {anio}, {cc}, '{escape_sql(combustible)}', {gal}, {hp}, '{escape_sql(aceite)}', '{cdn}', 85, true)"
    )

sql_lines.append(",\n".join(model_rows))
sql_lines.append("ON CONFLICT (marca_id, tipo, linea) DO UPDATE SET")
sql_lines.append("  modelo = EXCLUDED.modelo,")
sql_lines.append("  imagen_url = EXCLUDED.imagen_url,")
sql_lines.append("  cilindraje_cc = EXCLUDED.cilindraje_cc,")
sql_lines.append("  tipo_combustible = EXCLUDED.tipo_combustible,")
sql_lines.append("  aceite_recomendado = EXCLUDED.aceite_recomendado,")
sql_lines.append("  activo = true;\n")

# PASO 4: REGISTRO DE ACTUALIZACIÓN OTA BUILD 29
sql_lines.append("-- PASO 4: ACTUALIZACIÓN AUTOMÁTICA OTA (v1.2.12 Build 29)")
sql_lines.append("INSERT INTO public.app_versions (version_code, version_name, zip_url, release_notes, is_mandatory, min_supported_version)")
sql_lines.append("VALUES (")
sql_lines.append("  29,")
sql_lines.append("  '1.2.12',")
sql_lines.append("  'https://github.com/INGJUANRUIZTOBON/my_auto_guide/releases/download/1.1.0/app-release.apk',")
sql_lines.append("  '• Catálogo Expandido Autonal & Autoland: 32 marcas y 87 modelos con siluetas transparentes de alta resolución.\\n• Nuevas Marcas Oficiales: Changan, Chery, Deepal, Haval, Honda (Línea Carros), JMC y Opel.\\n• Modelos Iconos Añadidos: BYD Seagull, Yuan Plus, Qin Plus; Chery Tiggo 4; Suzuki Baleno, Fronx; VW Golf, Voyage; Audi Q5, BMW X2, Ford Fiesta.\\n• Arquitectura de Base de Datos Reforzada: Corrección de restricción única e indexación de alto rendimiento en Supabase.',")
sql_lines.append("  true,")
sql_lines.append("  1")
sql_lines.append(")")
sql_lines.append("ON CONFLICT (version_code) DO UPDATE SET")
sql_lines.append("  version_name = EXCLUDED.version_name,")
sql_lines.append("  zip_url = EXCLUDED.zip_url,")
sql_lines.append("  release_notes = EXCLUDED.release_notes,")
sql_lines.append("  is_mandatory = true;\n")

final_sql = "\n".join(sql_lines)
with open('supabase/migrations/20261112_add_autonal_and_autoland_catalog.sql', 'w', encoding='utf-8') as f:
    f.write(final_sql)

print(f"Migración SQL generada con éxito! Total modelos incluidos: {len(model_rows)}")
