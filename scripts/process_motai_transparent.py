import os
import json
import time
import re
from PIL import Image
from rembg import remove, new_session

SUPABASE_URL = 'https://iqdobggghorpuepuquhb.supabase.co'
BUCKET = 'catalog-assets'

with open('scripts/motai_selected_models.json', 'r', encoding='utf-8') as f:
    selected = json.load(f)

print(f"Iniciando recorte inteligente de {len(selected)} motocicletas con rembg (u2netp)...")
start_time = time.time()

session = new_session('u2netp')

brand_slug_map = {
    'AKT': 'akt',
    'Bajaj': 'bajaj',
    'Benelli': 'benelli',
    'Fratelli': 'fratelli',
    'Hero': 'hero',
    'Honda': 'honda',
    'KTM': 'ktm',
    'Kawasaki': 'kawasaki',
    'Kymco': 'kymco',
    'Royal Enfield': 'royal_enfield',
    'SYM': 'sym',
    'Suzuki': 'suzuki',
    'TVS': 'tvs',
    'Victory': 'victory',
}

def clean_slug(name):
    s = name.lower()
    s = s.replace('ë', 'e').replace('é', 'e').replace('á', 'a').replace('í', 'i').replace('ó', 'o').replace('ú', 'u')
    s = re.sub(r'[^a-z0-9]+', '_', s)
    return s.strip('_')

output_base = r'build\motai_transparent'
os.makedirs(output_base, exist_ok=True)

processed_list = []
success_count = 0

for i, item in enumerate(selected, 1):
    marca = item['marca']
    modelo = item['modelo']
    linea = item['linea']
    cc = item['cc']
    ano = item['ano']
    img_disk = item['img_disk']
    
    brand_slug = brand_slug_map.get(marca, clean_slug(marca))
    model_slug = f"{brand_slug}_{clean_slug(modelo)}"
    
    brand_out_dir = os.path.join(output_base, brand_slug)
    os.makedirs(brand_out_dir, exist_ok=True)
    
    out_file = os.path.join(brand_out_dir, f"{model_slug}.png")
    rel_asset_path = f"assets/motos/{brand_slug}/{model_slug}.png"
    cdn_url = f"{SUPABASE_URL}/storage/v1/object/public/{BUCKET}/{rel_asset_path}"
    
    item_start = time.time()
    try:
        img = Image.open(img_disk)
        # Remove background
        no_bg = remove(img, session=session)
        bbox = no_bg.getbbox()
        if bbox:
            cropped = no_bg.crop(bbox)
            canvas = Image.new('RGBA', (1200, 900), (0, 0, 0, 0))
            cropped.thumbnail((1100, 800), Image.Resampling.LANCZOS)
            x = (1200 - cropped.width) // 2
            y = (900 - cropped.height) // 2
            canvas.paste(cropped, (x, y), cropped)
            canvas.save(out_file, format='PNG', optimize=True)
        else:
            # Fallback if bbox is empty
            img_rgba = img.convert('RGBA')
            img_rgba.thumbnail((1200, 900), Image.Resampling.LANCZOS)
            img_rgba.save(out_file, format='PNG', optimize=True)
            
        file_kb = os.path.getsize(out_file) / 1024
        elapsed = time.time() - item_start
        print(f"[{i:02d}/{len(selected):02d}] ✔ {marca} {modelo} -> {out_file} ({file_kb:.1f} KB, {elapsed:.2f}s)")
        
        processed_list.append({
            'marca': marca,
            'marca_slug': brand_slug,
            'linea': linea,
            'modelo': modelo,
            'full_model': f"{marca} {modelo}",
            'ano': ano,
            'cc': cc,
            'disk_path': out_file,
            'rel_asset_path': rel_asset_path,
            'cdn_url': cdn_url
        })
        success_count += 1
    except Exception as e:
        print(f"[{i:02d}/{len(selected):02d}] ❌ Error en {marca} {modelo}: {e}")

total_elapsed = time.time() - start_time
print(f"\n=======================================================")
print(f"Recorte finalizado con éxito: {success_count}/{len(selected)} motocicletas")
print(f"Tiempo total: {total_elapsed:.1f}s (promedio: {total_elapsed/max(1, len(selected)):.2f}s/moto)")
print(f"=======================================================\n")

with open('scripts/motai_processed_final.json', 'w', encoding='utf-8') as f:
    json.dump(processed_list, f, indent=2, ensure_ascii=False)

print("Guardado en scripts/motai_processed_final.json")
