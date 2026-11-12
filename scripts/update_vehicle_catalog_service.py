# =============================================================================
# update_vehicle_catalog_service.py
# =============================================================================
import re
import json

def main():
    service_path = r"D:\Proyectos\my_auto_guide\lib\core\services\vehicle_catalog_service.dart"
    with open(service_path, 'r', encoding='utf-8') as f:
        content = f.read()

    with open(r"D:\Proyectos\my_auto_guide\scripts\autoland_processed_final.json", 'r', encoding='utf-8') as f:
        models = json.load(f)

    # Agrupar modelos por marca en mayúsculas
    by_brand = {}
    brand_logos = {}
    brand_colors = {}

    for m in models:
        b_name = m['brand_nombre'].upper()
        if b_name not in by_brand:
            by_brand[b_name] = []
        by_brand[b_name].append({
            'modelo': m['linea_formateada'].upper(),
            'img': m['rel_asset_path']
        })
        brand_logos[b_name] = m['brand_logo']
        brand_colors[b_name] = m['brand_color']

    # Añadir a _carCatalog
    # Encontrar el final del Map _carCatalog
    # Añadir las nuevas marcas antes del cierre del _carCatalog
    print(f"Marcas a integrar: {list(by_brand.keys())}")

    # Generar bloques de Dart para _carCatalog
    catalog_dart = []
    for b_name, m_list in by_brand.items():
        # Verificar si la marca ya está en _carCatalog
        pattern = rf"'{b_name}':\s*\[(.*?)\],"
        match = re.search(pattern, content, re.DOTALL)
        if match:
            # Añadir solo modelos que no estén
            existing_block = match.group(1)
            new_entries = []
            for item in m_list:
                if item['modelo'] not in existing_block:
                    new_entries.append(f"      {{'modelo': '{item['modelo']}', 'img': '{item['img']}'}},")
            if new_entries:
                replacement = match.group(0).replace("],", "\n" + "\n".join(new_entries) + "\n    ],")
                content = content.replace(match.group(0), replacement)
                print(f"Añadidos {len(new_entries)} modelos a marca existente {b_name}")
        else:
            # Nueva marca completa
            entries = "\n".join([f"      {{'modelo': '{item['modelo']}', 'img': '{item['img']}'}}," for item in m_list])
            block = f"    '{b_name}': [\n{entries}\n    ],"
            catalog_dart.append(block)

    if catalog_dart:
        # Insertar antes de '  };\n\n  final Map<String, String> _carLogos = {'
        insert_marker = "  };\n\n  final Map<String, String> _carLogos = {"
        new_blocks = "\n" + "\n".join(catalog_dart) + "\n"
        content = content.replace(insert_marker, new_blocks + insert_marker)
        print(f"Insertadas {len(catalog_dart)} nuevas marcas en _carCatalog")

    # Actualizar _carLogos
    for b_name, logo in brand_logos.items():
        if f"'{b_name}':" not in content[content.find('_carLogos'):content.find('_motoCatalog')]:
            # Insertar en _carLogos
            insert_marker_logo = "  final Map<String, String> _carLogos = {"
            content = content.replace(insert_marker_logo, f"{insert_marker_logo}\n    '{b_name}': '{logo}',")
            print(f"Añadido logo para {b_name}")

    # Actualizar _brandColors
    for b_name, color in brand_colors.items():
        if f"'{b_name}':" not in content[content.find('_brandColors'):]:
            hex_clean = color.replace('#', '')
            dart_color = f"const Color(0xFF{hex_clean})"
            insert_marker_color = "  final Map<String, Color> _brandColors = {"
            content = content.replace(insert_marker_color, f"{insert_marker_color}\n    '{b_name}': {dart_color},")
            print(f"Añadido color para {b_name}")

    with open(service_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("vehicle_catalog_service.dart actualizado con éxito!")

if __name__ == '__main__':
    main()
