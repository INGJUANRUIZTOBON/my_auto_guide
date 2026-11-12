import os
import json
import csv
import re
import urllib.request

SUPABASE_URL = 'https://iqdobggghorpuepuquhb.supabase.co'
ANON_KEY = 'sb_publishable_4ldD5RfYCB6fTFle_9rgAQ_JFv_fNsl'
headers = {'apikey': ANON_KEY, 'Authorization': f'Bearer {ANON_KEY}'}

# 1. Fetch existing models from Supabase
req = urllib.request.Request(f'{SUPABASE_URL}/rest/v1/catalogo_modelos?tipo=eq.moto&select=marca_id,linea,modelo', headers=headers)
with urllib.request.urlopen(req) as res:
    existing_motos = json.loads(res.read().decode())

def norm(text):
    return re.sub(r'[^a-z0-9]', '', (text or '').lower())

existing_by_brand = {}
for m in existing_motos:
    b = norm(m['marca_id'])
    existing_by_brand.setdefault(b, []).append({
        'linea': m['linea'],
        'modelo': m['modelo'],
        'norm_linea': norm(m['linea']),
        'norm_modelo': norm(m['modelo']),
    })

motai_dir = r'D:\Descargas\motai\motai'
csv_file = os.path.join(motai_dir, 'catalogo.csv')
with open(csv_file, 'r', encoding='utf-8') as f:
    rows = list(csv.DictReader(f))

def clean_model_name(marca, raw_model):
    m = raw_model.strip()
    if m.lower().startswith(marca.lower()):
        m = m[len(marca):].strip()
    m = re.sub(r'\s+', ' ', m).strip()
    return m

def extract_linea(marca, model_clean):
    parts = model_clean.split()
    if len(parts) > 0:
        return parts[0]
    return model_clean

selected_candidates = []
seen_motai_models = set()
discarded_dup_supabase = []
discarded_electric = []
discarded_dup_motai = []
missing_images = []

for r in rows:
    marca = r['marca'].strip()
    if marca.lower() in ('electric', 'revoo'):
        discarded_electric.append(f"{marca} - {r.get('nombre_vehiculo')}")
        continue
    
    cc_str = r.get('cilindraje', '').replace('cc', '').strip()
    if not cc_str or cc_str == '0':
        discarded_electric.append(f"{marca} - {r.get('nombre_vehiculo')} (0 cc)")
        continue
    
    raw_mod = r['modelo'].strip()
    model_clean = clean_model_name(marca, raw_mod)
    linea = extract_linea(marca, model_clean)
    
    norm_b = norm(marca)
    norm_m = norm(model_clean)
    norm_l = norm(linea)
    
    # Check duplicate against Supabase
    is_dup_supabase = False
    if norm_b in existing_by_brand:
        for ex in existing_by_brand[norm_b]:
            if norm_m == ex['norm_linea'] or norm_m == ex['norm_modelo']:
                is_dup_supabase = True
                break
            if len(ex['norm_linea']) >= 4 and ex['norm_linea'] in norm_m:
                is_dup_supabase = True
                break
            if len(norm_l) >= 4 and norm_l in ex['norm_modelo']:
                is_dup_supabase = True
                break
    
    if is_dup_supabase:
        discarded_dup_supabase.append(f"{marca} {model_clean}")
        continue
        
    # Check duplicate within this motai batch (keep highest year)
    key = (norm_b, norm_m)
    if key in seen_motai_models:
        discarded_dup_motai.append(f"{marca} {model_clean}")
        continue
    seen_motai_models.add(key)
    
    # Locate actual image file on disk
    nombre_v = r['nombre_vehiculo'].strip()
    row_id = r.get('\ufeffid') or r.get('id', '')
    brand_folder = os.path.join(motai_dir, marca)
    
    img_path = None
    if os.path.isdir(brand_folder):
        for sub in os.listdir(brand_folder):
            if sub.startswith(nombre_v) or (row_id and row_id in sub):
                sub_path = os.path.join(brand_folder, sub)
                for f in os.listdir(sub_path):
                    if f.lower().endswith(('.jpg', '.png', '.jpeg', '.webp')):
                        img_path = os.path.join(sub_path, f)
                        break
            if img_path:
                break
                
    if not img_path or not os.path.exists(img_path):
        missing_images.append(f"{marca} {model_clean}")
        continue

    selected_candidates.append({
        'marca': marca,
        'linea': linea,
        'modelo': model_clean,
        'full_name': f'{marca} {model_clean}',
        'ano': int(r.get('ano') or 2024),
        'cc': int(cc_str) if cc_str.isdigit() else 125,
        'img_disk': img_path,
        'row_id': row_id
    })

print(f"Total rows in catalogo.csv: {len(rows)}")
print(f"Discarded Electric: {len(discarded_electric)}")
print(f"Discarded Duplicates in Supabase: {len(discarded_dup_supabase)}")
print(f"Discarded Duplicates in Motai: {len(discarded_dup_motai)}")
print(f"Missing image files: {len(missing_images)}")
print(f"==> Total UNIQUE NEW candidates selected: {len(selected_candidates)}")

with open('scripts/motai_selected_models.json', 'w', encoding='utf-8') as f:
    json.dump(selected_candidates, f, indent=2, ensure_ascii=False)

by_b = {}
for c in selected_candidates:
    by_b.setdefault(c['marca'], []).append(c)

for b, items in sorted(by_b.items()):
    models_str = ", ".join([it['modelo'] for it in items[:6]])
    print(f"  {b} ({len(items)}): {models_str}")
