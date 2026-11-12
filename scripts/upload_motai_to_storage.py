import os
import json
import time
import requests
from concurrent.futures import ThreadPoolExecutor, as_completed

SUPABASE_URL = 'https://iqdobggghorpuepuquhb.supabase.co'
ANON_KEY = 'sb_publishable_4ldD5RfYCB6fTFle_9rgAQ_JFv_fNsl'
BUCKET = 'catalog-assets'

headers = {
    'apikey': ANON_KEY,
    'Authorization': f'Bearer {ANON_KEY}',
    'Content-Type': 'image/png',
    'x-upsert': 'true',
}

with open('scripts/motai_processed_final.json', 'r', encoding='utf-8') as f:
    motos = json.load(f)

# Collect files to upload
# 1. 62 motos
upload_jobs = []
for m in motos:
    local_p = m['disk_path']
    rel_p = m['rel_asset_path']
    upload_jobs.append((local_p, rel_p, m['full_model']))

# 2. Logos
logos = [
    ('assets/logos/benelli.png', 'assets/logos/benelli.png', 'Logo Benelli'),
    ('assets/logos/fratelli.png', 'assets/logos/fratelli.png', 'Logo Fratelli'),
    ('assets/logos/kymco.png', 'assets/logos/kymco.png', 'Logo Kymco'),
    ('assets/logos/sym.png', 'assets/logos/sym.png', 'Logo SYM'),
    ('assets/logos/royal_enfield.png', 'assets/logos/royal_enfield.png', 'Logo Royal Enfield'),
    ('assets/logos/royal_enfield.png', 'assets/logos/royal-enfield.png', 'Logo Royal Enfield (alias)'),
]
for local_p, rel_p, label in logos:
    if os.path.exists(local_p):
        upload_jobs.append((local_p, rel_p, label))

print(f"Iniciando subida a Supabase Storage '{BUCKET}' de {len(upload_jobs)} archivos...")

def upload_item(job):
    local_p, rel_p, label = job
    url = f"{SUPABASE_URL}/storage/v1/object/{BUCKET}/{rel_p}"
    try:
        with open(local_p, 'rb') as f:
            data = f.read()
        res = requests.post(url, headers=headers, data=data, timeout=30)
        if res.status_code in (200, 201):
            return True, rel_p, label, len(data), None
        return False, rel_p, label, len(data), f"HTTP {res.status_code}: {res.text[:80]}"
    except Exception as e:
        return False, rel_p, label, 0, str(e)

ok_count = 0
fail_count = 0
total_bytes = 0
start_time = time.time()

with ThreadPoolExecutor(max_workers=12) as executor:
    futures = {executor.submit(upload_item, j): j for j in upload_jobs}
    for i, fut in enumerate(as_completed(futures), 1):
        ok, rel_p, label, size_b, err = fut.result()
        if ok:
            ok_count += 1
            total_bytes += size_b
            print(f"[{i:02d}/{len(upload_jobs):02d}] ✔ {label} -> {rel_p} ({size_b/1024:.1f} KB)")
        else:
            fail_count += 1
            print(f"[{i:02d}/{len(upload_jobs):02d}] ❌ {label} -> {rel_p} ERROR: {err}")

elapsed = time.time() - start_time
print("\n=======================================================")
print(f"Subida finalizada: {ok_count} exitosos, {fail_count} fallidos")
print(f"Total datos subidos: {total_bytes / (1024*1024):.2f} MB en {elapsed:.1f}s")
print("=======================================================\n")
