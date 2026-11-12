import requests

test_urls = [
    ('Deepal S07 (Carro)', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/deepal/deepal_s07.png'),
    ('Deepal Logo (Marca)', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/deepal.png'),
    ('Audi Q5 (Carro)', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/audi/audi_q5.png'),
    ('Audi Logo (Marca)', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/audi_logo.png'),
    ('BMW X2 (Carro)', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/bmw/bmw_x2.png'),
    ('BYD Seagull (Carro)', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/byd/byd_seagull.png'),
    ('Chery Tiggo 4 (Carro)', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/chery/chery_tiggo_4.png'),
    ('Citroën C3 Aircross (Carro)', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/citroen/citroen_c3_aircross.png'),
    ('Ford Fiesta (Carro)', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/ford/ford_fiesta.png'),
    ('Haval H6 (Carro)', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/haval/haval_h6.png'),
    ('Jeep Wrangler (Carro)', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/jeep/jeep_wrangler_unlimited_4x4.png'),
    ('Suzuki Baleno (Carro)', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/suzuki/suzuki_baleno.png'),
    ('Tesla Model Y (Carro)', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/tesla/tesla_model_y.png'),
    ('VW Golf (Carro)', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/volkswagen/volkswagen_golf.png'),
    ('Yamaha MT-15 (Moto)', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/yamaha/mt15.png'),
]

print("-" * 105)
print(f"{'Activo / Vehículo':<30} | {'Status':<6} | {'Tamaño (KB)':<12} | {'Content-Type':<15} | {'URL'}")
print("-" * 105)

for name, url in test_urls:
    r = requests.get(url, timeout=10)
    size_kb = f"{len(r.content)/1024:.1f} KB"
    ctype = r.headers.get('content-type', '')
    print(f"{name:<30} | {r.status_code:<6} | {size_kb:<12} | {ctype:<15} | {url}")

print("-" * 105)
