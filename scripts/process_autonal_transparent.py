import os
import json
import time
import re
from PIL import Image
from rembg import remove, new_session

with open('scripts/autonal_final_35.json', 'r', encoding='utf-8') as f:
    models = json.load(f)

print(f"Iniciando recorte transparente de {len(models)} vehículos de Autonal...")
start_time = time.time()

session = new_session('u2netp')
processed_catalog = []

brand_slug_map = {
    'AUDI': 'audi',
    'BMW': 'bmw',
    'BYD': 'byd',
    'CHANGAN': 'changan',
    'CHERY': 'chery',
    'CHEVROLET': 'chevrolet',
    'CITROËN': 'citroen',
    'DEEPAL': 'deepal',
    'FORD': 'ford',
    'HAVAL': 'haval',
    'HONDA': 'honda',
    'HYUNDAI': 'hyundai',
    'JEEP': 'jeep',
    'JMC': 'jmc',
    'KIA': 'kia',
    'MINI': 'mini',
    'MITSUBISHI': 'mitsubishi',
    'OPEL': 'opel',
    'RENAULT': 'renault',
    'SEAT': 'seat',
    'SUZUKI': 'suzuki',
    'TESLA': 'tesla',
    'VOLKSWAGEN': 'volkswagen',
}

def clean_slug(name):
    s = name.lower()
    s = s.replace('ë', 'e').replace('é', 'e').replace('á', 'a').replace('í', 'i').replace('ó', 'o').replace('ú', 'u')
    s = re.sub(r'[^a-z0-9]+', '_', s)
    return s.strip('_')

def estimate_technical_specs(brand, line, info):
    fuel = info.get('combustible', 'Gasolina')
    folder = info.get('carpeta', '')
    title = info.get('titulo', '')
    combined = f"{folder} {title} {line}".upper()
    
    # Motor CC
    cc = 1600
    cc_match = re.search(r'\b(1\.[0234568]|2\.[024578]|3\.[056]|4\.[0]|660)\b', combined)
    if cc_match:
        val = cc_match.group(1)
        if '.' in val:
            cc = int(float(val) * 1000)
        else:
            cc = int(val)
    elif 'BEV' in combined or 'EV' in combined or 'ELECTRICO' in combined:
        cc = 0
        fuel = 'Eléctrico'

    if 'PHEV' in combined or 'MHEV' in combined or 'HEV' in combined or 'HIBRIDO' in combined:
        if fuel != 'Eléctrico':
            fuel = 'Híbrido'

    # Aceite recomendado
    if fuel == 'Eléctrico':
        oil = 'Líquido Refrigerante Batería EV'
        hp = 180.0
    elif 'DIE' in combined or 'DIESEL' in combined:
        fuel = 'Diésel'
        oil = '5W-30 Sintético Low SAPS DPF'
        hp = 170.0
    elif 'TURBO' in combined or cc <= 1400:
        oil = '0W-20 Sintético Dexos 1 / API SP'
        hp = 140.0
    elif cc >= 2400:
        oil = '5W-30 Sintético API SP'
        hp = 220.0
    else:
        oil = '5W-30 Sintético API SP'
        hp = 125.0

    year = 2023
    year_match = re.search(r'\b(201[4-9]|202[0-7])\b', combined)
    if year_match:
        year = int(year_match.group(1))

    return {
        'cc': cc,
        'fuel': fuel,
        'oil': oil,
        'hp': hp,
        'year': year
    }

for idx, m in enumerate(models, 1):
    src_path = m['image']
    brand_key = m['brand']
    line_key = m['line']
    brand_slug = brand_slug_map.get(brand_key, clean_slug(brand_key))
    dest_slug = clean_slug(f"{brand_slug}_{line_key}")
    
    out_dir = os.path.join('assets', 'carros', brand_slug)
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, f"{dest_slug}.png")
    asset_path = f"assets/carros/{brand_slug}/{dest_slug}.png"
    
    specs = estimate_technical_specs(brand_key, line_key, m.get('info', {}))
    
    # Recorte inteligente
    try:
        with Image.open(src_path) as im:
            im = im.convert('RGB')
            # Limitar tamaño máximo para velocidad
            max_size = 1200
            if max(im.size) > max_size:
                im.thumbnail((max_size, max_size), Image.Resampling.LANCZOS)
            
            nobg = remove(im, session=session)
            
            # Recortar caja delimitadora con 15px de margen
            bbox = nobg.getbbox()
            if bbox:
                w, h = nobg.size
                pad = 15
                crop_box = (
                    max(0, bbox[0] - pad),
                    max(0, bbox[1] - pad),
                    min(w, bbox[2] + pad),
                    min(h, bbox[3] + pad)
                )
                nobg = nobg.crop(crop_box)
            
            nobg.save(out_path, format='PNG', optimize=True)
            sz = os.path.getsize(out_path)
            print(f"[{idx:02d}/{len(models)}] {m['full_model']:<25} -> {asset_path} ({sz//1024} KB)")
    except Exception as e:
        print(f"Error procesando {m['full_model']}: {e}")
        continue
        
    processed_catalog.append({
        'brand': brand_key,
        'brand_slug': brand_slug,
        'line': line_key,
        'full_model': m['full_model'],
        'asset_path': asset_path,
        'cdn_url': f"https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/{asset_path}",
        'specs': specs
    })

elapsed = time.time() - start_time
print(f"Procesamiento finalizado en {elapsed:.1f} segundos. Total procesados: {len(processed_catalog)}")

with open('scripts/autonal_processed_final.json', 'w', encoding='utf-8') as f:
    json.dump(processed_catalog, f, indent=2, ensure_ascii=False)
