import requests

SUPABASE_URL = 'https://iqdobggghorpuepuquhb.supabase.co'
ANON_KEY = 'sb_publishable_4ldD5RfYCB6fTFle_9rgAQ_JFv_fNsl'
BUCKET = 'catalog-assets'

headers = {
    'apikey': ANON_KEY,
    'Authorization': f'Bearer {ANON_KEY}',
    'Content-Type': 'image/png',
    'x-upsert': 'true'
}

with open('assets/logos/deepal.png', 'rb') as f:
    data = f.read()

r = requests.post(f"{SUPABASE_URL}/storage/v1/object/{BUCKET}/assets/logos/deepal.png", headers=headers, data=data)
print("Upload deepal.png status:", r.status_code)
print("Upload response:", r.text)
