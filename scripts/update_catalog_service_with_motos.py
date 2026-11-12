import json
import re

with open('scripts/motai_processed_final.json', 'r', encoding='utf-8') as f:
    motos = json.load(f)

with open('lib/core/services/vehicle_catalog_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update _carLogos with missing car brands if not present
car_logos_to_add = {
    'CHANGAN': 'assets/logos/changan.png',
    'CHERY': 'assets/logos/chery.png',
    'DEEPAL': 'assets/logos/deepal.png',
    'HAVAL': 'assets/logos/haval.png',
    'HONDA': 'assets/logos/honda_logo.png',
    'JMC': 'assets/logos/jmc.png',
    'OPEL': 'assets/logos/opel.png',
}

car_logos_block = ""
for k, v in car_logos_to_add.items():
    if f"'{k}':" not in content[:content.find('_motoCatalog')]:
        car_logos_block += f"    '{k}': '{v}',\n"

if car_logos_block:
    content = content.replace("  final Map<String, String> _carLogos = {", f"  final Map<String, String> _carLogos = {{\n{car_logos_block}")
    print("Added car logos to _carLogos")

# 2. Update _motoLogos with new motorcycle brands
moto_logos_to_add = {
    'BENELLI': 'assets/logos/benelli.png',
    'FRATELLI': 'assets/logos/fratelli.png',
    'KYMCO': 'assets/logos/kymco.png',
    'SYM': 'assets/logos/sym.png',
    'ROYAL ENFIELD': 'assets/logos/royal_enfield.png',
    'VICTORY': 'assets/logos/victori_logo.png',
}

moto_logos_block = ""
for k, v in moto_logos_to_add.items():
    if f"'{k}':" not in content[content.find('_motoLogos'):content.find('_brandColors')]:
        moto_logos_block += f"    '{k}': '{v}',\n"

if moto_logos_block:
    content = content.replace("  final Map<String, String> _motoLogos = {", f"  final Map<String, String> _motoLogos = {{\n{moto_logos_block}")
    print("Added moto logos to _motoLogos")

# 3. Update _brandColors with both cars & motos
brand_colors_to_add = {
    'CHANGAN': 'const Color(0xFF003087)',
    'CHERY': 'const Color(0xFFC8102E)',
    'DEEPAL': 'const Color(0xFF007A87)',
    'HAVAL': 'const Color(0xFFD22630)',
    'JMC': 'const Color(0xFF003A70)',
    'OPEL': 'const Color(0xFFFFD100)',
    'BENELLI': 'const Color(0xFF005C30)',
    'FRATELLI': 'const Color(0xFFC41230)',
    'KYMCO': 'const Color(0xFFE60012)',
    'SYM': 'const Color(0xFF005BAC)',
    'ROYAL ENFIELD': 'const Color(0xFF8B1E1E)',
    'VICTORY': 'const Color(0xFFCBA73D)',
}

brand_colors_block = ""
for k, v in brand_colors_to_add.items():
    if f"'{k}':" not in content[content.find('_brandColors'):]:
        brand_colors_block += f"    '{k}': {v},\n"

if brand_colors_block:
    content = content.replace("  final Map<String, Color> _brandColors = {", f"  final Map<String, Color> _brandColors = {{\n{brand_colors_block}")
    print("Added brand colors to _brandColors")

# 4. Group new motos by uppercase brand
by_brand = {}
for m in motos:
    b = m['marca'].upper()
    by_brand.setdefault(b, []).append({
        'modelo': m['modelo'],
        'img': m['rel_asset_path']
    })

# Check which brands are missing entirely from _motoCatalog
new_moto_brands_block = ""
for b, items in sorted(by_brand.items()):
    # If brand doesn't exist in _motoCatalog
    search_str = f"'{b}': ["
    if search_str not in content[content.find('_motoCatalog'):content.find('_motoLogos')]:
        new_moto_brands_block += f"    '{b}': [\n"
        for it in items:
            new_moto_brands_block += f"      {{'modelo': '{it['modelo']}', 'img': '{it['img']}'}},\n"
        new_moto_brands_block += "    ],\n"
    else:
        # Append items to existing brand
        # Find position of search_str
        pos = content.find(search_str)
        bracket_close = content.find("],", pos)
        if bracket_close != -1:
            items_str = ""
            for it in items:
                if f"'{it['modelo']}'" not in content[pos:bracket_close]:
                    items_str += f"      {{'modelo': '{it['modelo']}', 'img': '{it['img']}'}},\n"
            if items_str:
                content = content[:bracket_close] + items_str + content[bracket_close:]
                print(f"Appended new models to {b}")

if new_moto_brands_block:
    content = content.replace("  final Map<String, List<Map<String, String>>> _motoCatalog = {", f"  final Map<String, List<Map<String, String>>> _motoCatalog = {{\n{new_moto_brands_block}")
    print("Added new motorcycle brands to _motoCatalog")

with open('lib/core/services/vehicle_catalog_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("vehicle_catalog_service.dart actualizado con éxito.")
