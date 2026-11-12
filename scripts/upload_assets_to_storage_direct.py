import os
import requests
import mimetypes

SUPABASE_URL = 'https://iqdobggghorpuepuquhb.supabase.co'
ANON_KEY = 'sb_publishable_4ldD5RfYCB6fTFle_9rgAQ_JFv_fNsl'
BUCKET = 'catalog-assets'

headers_base = {
    'apikey': ANON_KEY,
    'Authorization': f'Bearer {ANON_KEY}',
    'x-upsert': 'true'
}

def upload_folder(folder_path):
    success = 0
    fail = 0
    for root, _, files in os.walk(folder_path):
        for f in files:
            if not f.lower().endswith(('.png', '.jpg', '.jpeg', '.svg', '.webp')):
                continue
            local_path = os.path.join(root, f)
            rel_path = os.path.relpath(local_path).replace('\\', '/')
            if not rel_path.startswith('assets/'):
                rel_path = f"assets/{rel_path}"
                
            mime, _ = mimetypes.guess_type(local_path)
            if not mime:
                mime = 'image/png'
                
            headers = dict(headers_base)
            headers['Content-Type'] = mime
            
            url = f"{SUPABASE_URL}/storage/v1/object/{BUCKET}/{rel_path}"
            try:
                with open(local_path, 'rb') as file_data:
                    res = requests.post(url, headers=headers, data=file_data)
                if res.status_code in (200, 201):
                    print(f"  [OK] {rel_path}")
                    success += 1
                else:
                    print(f"  [WARN {res.status_code}] {rel_path} -> {res.text[:80]}")
                    fail += 1
            except Exception as e:
                print(f"  [ERR] {rel_path} -> {e}")
                fail += 1
                
    return success, fail

if __name__ == '__main__':
    print("Iniciando sincronización completa de assets a Supabase Storage...")
    total_ok = 0
    total_fail = 0
    for d in ['assets/logos', 'assets/carros', 'assets/motos']:
        if os.path.exists(d):
            print(f"\nSubiendo carpeta: {d}")
            ok, fail = upload_folder(d)
            total_ok += ok
            total_fail += fail
            
    print(f"\nResumen final: {total_ok} subidos con éxito, {total_fail} fallidos.")
