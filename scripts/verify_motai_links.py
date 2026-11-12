import random
import json
import urllib.request

with open('scripts/motai_processed_final.json', 'r', encoding='utf-8') as f:
    motos = json.load(f)

# Pick 12 random motos
sample_motos = random.sample(motos, min(12, len(motos)))

test_urls = []
for m in sample_motos:
    test_urls.append((f"{m['full_model']} (Moto)", m['cdn_url']))

# Add logos
logos = [
    ('Benelli Logo', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/benelli.png'),
    ('Kymco Logo', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/kymco.png'),
    ('SYM Logo', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/sym.png'),
    ('Fratelli Logo', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/fratelli.png'),
    ('Royal Enfield Logo', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/royal_enfield.png'),
]
test_urls.extend(logos)

print(f"Probando {len(test_urls)} URLs públicas en Supabase CDN sin autenticación...")
success_count = 0

for label, url in test_urls:
    try:
        req = urllib.request.Request(url, method='HEAD')
        with urllib.request.urlopen(req, timeout=10) as res:
            status = res.status
            size_kb = int(res.headers.get('Content-Length', 0)) / 1024
            ctype = res.headers.get('Content-Type')
            if status == 200:
                print(f"✔ HTTP 200 OK | {size_kb:6.1f} KB | {ctype} | {label}")
                success_count += 1
            else:
                print(f"❌ HTTP {status} | {label} ({url})")
    except Exception as e:
        print(f"❌ ERROR: {e} | {label} ({url})")

print(f"\nResultado final de verificación: {success_count}/{len(test_urls)} enlaces verificados.")
if success_count == len(test_urls):
    print("🚀 TODOS LOS ENLACES PÚBLICOS ESTÁN ACTIVOS Y FUNCIONANDO AL 100%.")
else:
    print("⚠️ ALGUNOS ENLACES FALLARON.")
