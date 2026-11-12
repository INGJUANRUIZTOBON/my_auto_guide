import os
import re
import json
from PIL import Image

def audit():
    print("==================================================")
    print("1. AUDITORÍA VEHICLE_CATALOG_SERVICE.DART (LOCAL)")
    print("==================================================")
    with open('lib/core/services/vehicle_catalog_service.dart', 'r', encoding='utf-8') as f:
        dart_text = f.read()

    dart_assets = set(re.findall(r"'assets/([^']+)'", dart_text))
    missing_dart = []
    invalid_mode_dart = []

    for rel in dart_assets:
        full = os.path.join('assets', rel)
        if not os.path.exists(full):
            missing_dart.append(full)
        else:
            try:
                with Image.open(full) as im:
                    if im.mode != 'RGBA':
                        invalid_mode_dart.append((full, im.mode))
            except Exception as e:
                missing_dart.append(f"{full} (CORRUPT: {e})")

    print(f"Total assets en VehicleCatalogService: {len(dart_assets)}")
    print(f"Faltantes en disco: {len(missing_dart)}")
    for m in missing_dart:
        print(f"  ❌ Faltante: {m}")
    if invalid_mode_dart:
        print(f"Modo no RGBA: {len(invalid_mode_dart)}")
        for p, m in invalid_mode_dart:
            print(f"  ⚠️ Modo {m}: {p}")
    else:
        print("✔ Todos los assets locales son RGBA válidos.")

    print("\n==================================================")
    print("2. AUDITORÍA SUPABASE CATALOGO_MODELOS (NUBE)")
    print("==================================================")
    # Read .env for Supabase credentials
    if os.path.exists('.env'):
        env_vars = {}
        with open('.env', 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    k, v = line.split('=', 1)
                    env_vars[k.strip()] = v.strip()
        
        supabase_url = env_vars.get('SUPABASE_URL')
        supabase_key = env_vars.get('SUPABASE_SERVICE_KEY') or env_vars.get('SUPABASE_ANON_KEY')

        if supabase_url and supabase_key:
            import urllib.request
            req = urllib.request.Request(
                f"{supabase_url}/rest/v1/catalogo_modelos?select=id,marca_id,tipo,linea,modelo,imagen_url&activo=eq.true",
                headers={
                    'apikey': supabase_key,
                    'Authorization': f'Bearer {supabase_key}'
                }
            )
            try:
                with urllib.request.urlopen(req) as resp:
                    models = json.loads(resp.read().decode('utf-8'))
                    print(f"Total modelos activos en Supabase: {len(models)}")
                    missing_supa = []
                    for mod in models:
                        img = mod.get('imagen_url') or ''
                        if not os.path.exists(img):
                            missing_supa.append((mod['marca_id'], mod['modelo'], img))
                    print(f"Modelos de Supabase sin asset en disco: {len(missing_supa)}")
                    for marca, modelo, img in missing_supa:
                        print(f"  ❌ [{marca.upper()}] {modelo} -> {img}")
                    if not missing_supa:
                        print("✔ ¡100% de los modelos de Supabase existen en disco!")
            except Exception as e:
                print(f"Error consultando Supabase: {e}")

if __name__ == '__main__':
    audit()
