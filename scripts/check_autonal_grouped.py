import json

with open('scripts/autonal_processed_final.json', 'r', encoding='utf-8') as f:
    items = json.load(f)

by_brand = {}
for x in items:
    by_brand.setdefault(x['brand'], []).append(x)

print(f"Total marcas con modelos en Autonal: {len(by_brand)}")
for b, l in sorted(by_brand.items()):
    print(f"{b} ({len(l)}): {', '.join(x['line'] for x in l)}")
