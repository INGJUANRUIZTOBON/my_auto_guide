import requests

SUPABASE_URL = 'https://iqdobggghorpuepuquhb.supabase.co'
SECRET_KEY = 'sb_secret_3g9hjQsbxUFhwvsx-32qjQ_fi-l7MoD'
ANON_KEY = 'sb_publishable_4ldD5RfYCB6fTFle_9rgAQ_JFv_fNsl'
BUCKET = 'catalog-assets'

# Test 1: apikey header only
headers1 = {
    'apikey': SECRET_KEY,
}
r1 = requests.get(f"{SUPABASE_URL}/storage/v1/bucket", headers=headers1)
print("Test 1 (GET /storage/v1/bucket with apikey=SECRET_KEY):", r1.status_code, r1.text[:100])

# Test 2: with Authorization: Bearer SECRET_KEY
headers2 = {
    'apikey': SECRET_KEY,
    'Authorization': f'Bearer {SECRET_KEY}'
}
r2 = requests.get(f"{SUPABASE_URL}/storage/v1/bucket", headers=headers2)
print("Test 2 (GET /storage/v1/bucket with Bearer SECRET_KEY):", r2.status_code, r2.text[:100])

# Test 3: with apikey=ANON_KEY
headers3 = {
    'apikey': ANON_KEY,
    'Authorization': f'Bearer {ANON_KEY}'
}
r3 = requests.get(f"{SUPABASE_URL}/storage/v1/bucket", headers=headers3)
print("Test 3 (GET /storage/v1/bucket with Bearer ANON_KEY):", r3.status_code, r3.text[:100])
