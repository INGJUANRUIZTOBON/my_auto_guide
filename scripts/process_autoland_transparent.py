# =============================================================================
# process_autoland_transparent.py — RECORTE AUTOMÁTICO Y MIGRACIÓN SUPABASE
# =============================================================================

import os
import json
import re
import time
from PIL import Image
from rembg import remove, new_session

BASE_STORAGE = "https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets"
DEST_ASSETS_ROOT = r"D:\Proyectos\my_auto_guide\assets\carros"

def clean_slug(s):
    s = s.lower().strip()
    s = re.sub(r'[^a-z0-9]+', '_', s)
    return s.strip('_')

def format_clean_linea(linea):
    l = linea.strip()
    if l.lower() == 'peugeot': return '2008'
    if l.upper() == 'F150': return 'F-150'
    if l.upper() == 'X TRAIL': return 'X-Trail'
    if l.upper() == 'CX60': return 'CX-60'
    if l.upper() == 'CX90': return 'CX-90'
    if l.upper() == '218I': return '218i Gran Coupé'
    if l.upper() == '530I': return '530i Sedan'
    if l.upper() == 'C 200': return 'Clase C 200'
    if l.upper() == 'CLA 250': return 'CLA 250'
    if l.upper() == 'CLA 35': return 'CLA 35 AMG'
    if l.upper() == 'CLE 300': return 'CLE 300 Coupé'
    if l.upper() == 'EQA 250+': return 'EQA 250+ Eléctrico'
    if l.upper() == 'GLA 250': return 'GLA 250'
    if l.upper() == 'GLC 300': return 'GLC 300 4MATIC'
    if l.upper() == 'GLC 350 E': return 'GLC 350e Híbrido'
    if l.upper() == 'GLE 450': return 'GLE 450 4MATIC'
    if l.upper() == 'EC40': return 'EC40 Recharge Eléctrico'
    if l.upper() == 'XC40': return 'XC40 Recharge'
    if l.upper() == 'XC60': return 'XC60 Recharge'
    if l.upper() == 'MODEL 3': return 'Model 3'
    if l.upper() == 'WRANGLER UNLIMITED': return 'Wrangler Unlimited 4x4'
    return l

def main():
    json_path = r"D:\Proyectos\my_auto_guide\scripts\autoland_selected_models.json"
    with open(json_path, 'r', encoding='utf-8') as f:
        models = json.load(f)

    print(f"Iniciando recorte de {len(models)} modelos con sesión u2netp...")
    session = new_session('u2netp')

    processed_models = []
    t_start = time.time()

    for idx, item in enumerate(models, 1):
        brand_id = item['brand_id']
        linea_clean = format_clean_linea(item['linea'])
        slug = clean_slug(f"{brand_id}_{linea_clean}")
        brand_folder = os.path.join(DEST_ASSETS_ROOT, brand_id)
        os.makedirs(brand_folder, exist_ok=True)

        dest_png = os.path.join(brand_folder, f"{slug}.png")
        rel_asset_path = f"assets/carros/{brand_id}/{slug}.png"
        cdn_url = f"{BASE_STORAGE}/{rel_asset_path}"

        print(f"[{idx}/{len(models)}] Procesando: {item['brand_nombre']} {linea_clean}...")
        
        # Recorte con rembg
        t0 = time.time()
        try:
            img = Image.open(item['src_img'])
            # Escalar a max 900px antes de procesar para máxima nitidez y velocidad
            max_dim = 900
            if max(img.size) > max_dim:
                ratio = max_dim / max(img.size)
                new_size = (int(img.size[0] * ratio), int(img.size[1] * ratio))
                img = img.resize(new_size, Image.Resampling.LANCZOS)

            transparent = remove(img, session=session)
            
            # Recortar márgenes transparentes (tight bbox)
            bbox = transparent.getbbox()
            if bbox:
                transparent = transparent.crop(bbox)

            transparent.save(dest_png, 'PNG', optimize=True)
            elapsed = round(time.time() - t0, 2)
            print(f" -> Guardado en {dest_png} ({elapsed}s)")
        except Exception as e:
            print(f" -> ERROR procesando {item['src_img']}: {e}")
            continue

        item['linea_formateada'] = linea_clean
        item['dest_png'] = dest_png
        item['rel_asset_path'] = rel_asset_path
        item['cdn_url'] = cdn_url
        processed_models.append(item)

    print(f"\nRecorte completado con éxito: {len(processed_models)} autos en {round(time.time() - t_start, 1)}s")

    # Guardar JSON final
    with open(r"D:\Proyectos\my_auto_guide\scripts\autoland_processed_final.json", 'w', encoding='utf-8') as f:
        json.dump(processed_models, f, indent=2, ensure_ascii=False)

    # Generar Script SQL de migración
    sql_path = r"D:\Proyectos\my_auto_guide\supabase\migrations\add_autoland_colombia_catalog.sql"
    generate_sql_migration(processed_models, sql_path)
    print(f"Script SQL generado en: {sql_path}")

def generate_sql_migration(models, output_sql_path):
    # Obtener marcas únicas
    brands_map = {}
    for m in models:
        bid = m['brand_id']
        if bid not in brands_map:
            brands_map[bid] = {
                'id': bid,
                'nombre': m['brand_nombre'],
                'color_hex': m['brand_color'],
                'pais_origen': m['brand_pais'],
                'popularidad': m['brand_pop'],
                'logo_url': f"{BASE_STORAGE}/{m['brand_logo']}",
                'tipo': 'ambos' if bid in ['bmw', 'suzuki', 'honda'] else 'carro'
            }

    sql = []
    sql.append("-- =============================================================================")
    sql.append("-- MIGRACIÓN AUTOLAND COLOMBIA: 24 MARCAS Y 52 MODELOS CON FOTOS TRANSPARENTES")
    sql.append("-- =============================================================================")
    sql.append("")

    # 1. Upsert marcas
    sql.append("-- 1. REGISTRO Y ACTUALIZACIÓN DE MARCAS AUTOMOTRICES")
    sql.append("INSERT INTO catalogo_marcas (id, nombre, tipo, logo_url, color_hex, pais_origen, popularidad, activo)")
    sql.append("VALUES")
    brand_values = []
    for b in brands_map.values():
        val = f"  ('{b['id']}', '{b['nombre']}', '{b['tipo']}', '{b['logo_url']}', '{b['color_hex']}', '{b['pais_origen']}', {b['popularidad']}, true)"
        brand_values.append(val)
    sql.append(",\n".join(brand_values))
    sql.append("ON CONFLICT (id) DO UPDATE SET")
    sql.append("  nombre = EXCLUDED.nombre,")
    sql.append("  logo_url = EXCLUDED.logo_url,")
    sql.append("  color_hex = EXCLUDED.color_hex,")
    sql.append("  popularidad = GREATEST(catalogo_marcas.popularidad, EXCLUDED.popularidad),")
    sql.append("  activo = true;")
    sql.append("")

    # 2. Upsert modelos
    sql.append("-- 2. REGISTRO DE MODELOS COLOMBIANOS AUTOLAND")
    sql.append("INSERT INTO catalogo_modelos (marca_id, tipo, linea, modelo, anio_inicio, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)")
    sql.append("VALUES")
    model_values = []
    for m in models:
        specs = m['specs']
        marca_id = m['brand_id']
        linea = m['linea_formateada'].replace("'", "''")
        modelo_nombre = f"{m['brand_nombre']} {linea}".replace("'", "''")
        anio = m['anio']
        cc = specs['cilindraje_cc']
        comb = specs['tipo_combustible']
        tanque = 14.5 if comb != 'Eléctrico' else 0.0
        hp = specs['potencia_hp']
        aceite = specs['aceite_recomendado']
        img = m['cdn_url']
        pop = 85

        val = f"  ('{marca_id}', 'carro', '{linea}', '{modelo_nombre}', {anio}, {cc}, '{comb}', {tanque}, {hp}, '{aceite}', '{img}', {pop}, true)"
        model_values.append(val)

    sql.append(",\n".join(model_values))
    sql.append("ON CONFLICT (marca_id, tipo, linea) DO UPDATE SET")
    sql.append("  modelo = EXCLUDED.modelo,")
    sql.append("  imagen_url = EXCLUDED.imagen_url,")
    sql.append("  cilindraje_cc = EXCLUDED.cilindraje_cc,")
    sql.append("  tipo_combustible = EXCLUDED.tipo_combustible,")
    sql.append("  aceite_recomendado = EXCLUDED.aceite_recomendado,")
    sql.append("  activo = true;")
    sql.append("")

    with open(output_sql_path, 'w', encoding='utf-8') as f:
        f.write("\n".join(sql))

if __name__ == '__main__':
    main()
