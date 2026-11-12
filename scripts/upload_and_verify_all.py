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

def check_permission():
    url = f"{SUPABASE_URL}/storage/v1/object/{BUCKET}/assets/logos/deepal.png"
    h = dict(headers_base)
    h['Content-Type'] = 'image/png'
    try:
        with open('assets/logos/deepal.png', 'rb') as f:
            data = f.read()
        r = requests.post(url, headers=h, data=data)
        if r.status_code in (200, 201):
            return True, "Permiso concedido (200/201)"
        return False, f"HTTP {r.status_code}: {r.text}"
    except Exception as e:
        return False, str(e)

def upload_all_assets():
    folders = ['assets/logos', 'assets/carros', 'assets/motos']
    total_uploaded = 0
    total_failed = 0
    
    for folder in folders:
        if not os.path.exists(folder):
            continue
        print(f"\n--- Subiendo carpeta: {folder} ---")
        for root, _, files in os.walk(folder):
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
                    with open(local_path, 'rb') as fd:
                        res = requests.post(url, headers=headers, data=fd)
                    if res.status_code in (200, 201):
                        total_uploaded += 1
                        if total_uploaded % 20 == 0:
                            print(f"  [Progreso] {total_uploaded} archivos subidos...")
                    else:
                        print(f"  [Fallo HTTP {res.status_code}] {rel_path}: {res.text[:60]}")
                        total_failed += 1
                except Exception as e:
                    print(f"  [Error] {rel_path}: {e}")
                    total_failed += 1
                    
    print(f"\nTotal subidos exitosamente: {total_uploaded}")
    print(f"Total fallidos: {total_failed}")
    return total_uploaded

def verify_sample_urls():
    test_urls = [
        ("Deepal S07 (Carro)", f"{SUPABASE_URL}/storage/v1/object/public/{BUCKET}/assets/carros/deepal/deepal_s07.png"),
        ("Deepal Logo", f"{SUPABASE_URL}/storage/v1/object/public/{BUCKET}/assets/logos/deepal.png"),
        ("Audi Q5 (Carro)", f"{SUPABASE_URL}/storage/v1/object/public/{BUCKET}/assets/carros/audi/audi_q5.png"),
        ("Audi Logo", f"{SUPABASE_URL}/storage/v1/object/public/{BUCKET}/assets/logos/audi_logo.png"),
        ("BMW X2 (Carro)", f"{SUPABASE_URL}/storage/v1/object/public/{BUCKET}/assets/carros/bmw/bmw_x2.png"),
        ("BYD Seagull (Carro)", f"{SUPABASE_URL}/storage/v1/object/public/{BUCKET}/assets/carros/byd/byd_seagull.png"),
        ("Chery Tiggo 4 (Carro)", f"{SUPABASE_URL}/storage/v1/object/public/{BUCKET}/assets/carros/chery/chery_tiggo_4.png"),
        ("Citroën C3 Aircross (Carro)", f"{SUPABASE_URL}/storage/v1/object/public/{BUCKET}/assets/carros/citroen/citroen_c3_aircross.png"),
        ("Ford Fiesta (Carro)", f"{SUPABASE_URL}/storage/v1/object/public/{BUCKET}/assets/carros/ford/ford_fiesta.png"),
        ("Haval H6 (Carro)", f"{SUPABASE_URL}/storage/v1/object/public/{BUCKET}/assets/carros/haval/haval_h6.png"),
        ("Jeep Wrangler (Carro)", f"{SUPABASE_URL}/storage/v1/object/public/{BUCKET}/assets/carros/jeep/jeep_wrangler_unlimited_4x4.png"),
        ("Suzuki Baleno (Carro)", f"{SUPABASE_URL}/storage/v1/object/public/{BUCKET}/assets/carros/suzuki/suzuki_baleno.png"),
        ("Tesla Model Y (Carro)", f"{SUPABASE_URL}/storage/v1/object/public/{BUCKET}/assets/carros/tesla/tesla_model_y.png"),
        ("VW Golf (Carro)", f"{SUPABASE_URL}/storage/v1/object/public/{BUCKET}/assets/carros/volkswagen/volkswagen_golf.png"),
        ("Yamaha MT-15 (Moto)", f"{SUPABASE_URL}/storage/v1/object/public/{BUCKET}/assets/motos/yamaha/mt15.png"),
    ]
    
    print("\n================ VERIFICACIÓN DE ENLACES PÚBLICOS ================")
    verified_count = 0
    results = []
    
    for name, url in test_urls:
        try:
            r = requests.get(url, timeout=10)
            status = r.status_code
            content_type = r.headers.get('content-type', 'unknown')
            size_bytes = len(r.content)
            size_kb = round(size_bytes / 1024, 1)
            is_ok = (status == 200 and size_bytes > 500)
            if is_ok:
                verified_count += 1
            results.append((name, url, status, f"{size_kb} KB", content_type, "✅ OK" if is_ok else "❌ ERROR"))
        except Exception as e:
            results.append((name, url, "ERR", "0 KB", str(e), "❌ ERROR"))
            
    print(f"\nResultados: {verified_count}/{len(test_urls)} enlaces verificados correctamente con HTTP 200.")
    print("-" * 110)
    print(f"{'Modelo / Activo':<30} | {'Status':<7} | {'Tamaño':<10} | {'Content-Type':<18} | {'Estado'}")
    print("-" * 110)
    for r in results:
        print(f"{r[0]:<30} | {str(r[2]):<7} | {r[3]:<10} | {r[4]:<18} | {r[5]}")
    print("-" * 110)
    return verified_count, results

if __name__ == '__main__':
    ok, msg = check_permission()
    print("Estado de permisos en Supabase Storage:", msg)
    if ok:
        upload_all_assets()
        verify_sample_urls()
    else:
        print("\n[ALERTA] RLS aún no permite la subida. Requiere ejecutar el SQL de políticas en Supabase.")
        verify_sample_urls()
