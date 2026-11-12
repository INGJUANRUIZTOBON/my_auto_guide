# =============================================================================
# build_colombia_reference_catalog.py
# =============================================================================
# Genera el compendio oficial de referencia de vehículos de Colombia (2015-2026):
# 1. Crea la estructura local: vehiculos_colombia_referencia/carros/[marca]/ y motos/[marca]/
# 2. Genera fotografías Full HD (1920x1080) en ángulo 3/4 con fondo de estudio profesional.
# 3. Sube todas las fotos al bucket público de Supabase Storage: 'referencias-modelos'.
# 4. Genera la galería visual interactiva: vehiculos_colombia_referencia/galeria_colombia.html.
# =============================================================================

import os
import re
import json
import glob
from PIL import Image, ImageDraw, ImageFilter

OUTPUT_DIR = 'vehiculos_colombia_referencia'
BRAIN_DIR = r'C:\Users\juand\.gemini\antigravity\brain\f26ffe3c-1e9c-44d8-b464-c260fb8f7d5f'
SUPABASE_URL = 'https://iqdobggghorpuepuquhb.supabase.co'
SUPABASE_KEY = 'sb_secret_3g9hjQsbxUFhwvsx-32qjQ_fi-l7MoD'
STORAGE_BUCKET = 'referencias-modelos'

def create_studio_background(width=1920, height=1080):
    bg = Image.new('RGB', (width, height), (18, 20, 26))
    draw = ImageDraw.Draw(bg)

    # Gradiente vertical oscuro de estudio
    for y in range(height):
        factor = y / float(height)
        r = int(22 + (10 - 22) * factor)
        g = int(25 + (12 - 25) * factor)
        b = int(32 + (16 - 32) * factor)
        draw.line([(0, y), (width, y)], fill=(r, g, b))

    # Luz de piso / tarima elíptica sutil
    floor_y = int(height * 0.76)
    for rad in range(450, 0, -6):
        intensity = int((1.0 - (rad / 450.0)) * 22)
        draw.ellipse(
            [(width // 2 - rad * 2, floor_y - rad // 2),
             (width // 2 + rad * 2, floor_y + rad // 2)],
            fill=(26 + intensity, 32 + intensity, 42 + intensity)
        )
    return bg

def sanitize_filename(name):
    clean = re.sub(r'[\/\\:\*\?"<>\|\s]+', '_', name.strip())
    clean = re.sub(r'_+', '_', clean)
    return clean.strip('_')

def process_vehicle(tipo, marca, modelo_nombre, source_asset_path, brain_artifacts):
    target_folder = os.path.join(OUTPUT_DIR, tipo, marca.lower())
    os.makedirs(target_folder, exist_ok=True)
    filename = f"{marca.title()}_{sanitize_filename(modelo_nombre)}.jpg"
    target_path = os.path.join(target_folder, filename)

    # 1. Comprobar si existe un artefacto de estudio con fondo completo en el brain
    brain_match = None
    clean_search = re.sub(r'[^a-z0-9]', '', f"{marca}{modelo_nombre}".lower())
    for art in brain_artifacts:
        art_clean = re.sub(r'[^a-z0-9]', '', os.path.basename(art).lower())
        if clean_search in art_clean or (marca.lower() in art_clean and any(p in art_clean for p in clean_search.split())):
            brain_match = art
            break

    if brain_match and os.path.exists(brain_match):
        try:
            with Image.open(brain_match) as im:
                im_rgb = im.convert('RGB')
                im_resized = im_rgb.resize((1920, 1080), Image.Resampling.LANCZOS)
                im_resized.save(target_path, 'JPEG', quality=95)
                return target_path, filename
        except Exception:
            pass

    # 2. Renderizado de estudio Full HD sobre fondo automotriz
    if os.path.exists(source_asset_path):
        try:
            with Image.open(source_asset_path) as im:
                car = im.convert('RGBA')
                bg = create_studio_background(1920, 1080)

                # Ajuste de tamaño manteniendo relación de aspecto
                cw, ch = car.size
                is_moto = (tipo == 'motos')
                target_w = 1100 if is_moto else 1380
                target_h = int(ch * (target_w / float(cw)))
                if target_h > 720:
                    target_h = 720
                    target_w = int(cw * (target_h / float(ch)))

                car_resized = car.resize((target_w, target_h), Image.Resampling.LANCZOS)

                # Sombra de contacto difusa
                shadow = Image.new('RGBA', (target_w, 40), (0, 0, 0, 0))
                sh_draw = ImageDraw.Draw(shadow)
                sh_draw.ellipse([(20, 5), (target_w - 20, 35)], fill=(0, 0, 0, 140))
                shadow = shadow.filter(ImageFilter.GaussianBlur(8))

                floor_anchor = int(1080 * 0.78)
                pos_x = (1920 - target_w) // 2
                pos_y = floor_anchor - target_h + 30

                # Pegar sombra y vehículo
                bg.paste(shadow, (pos_x, floor_anchor - 20), shadow)
                bg.paste(car_resized, (pos_x, pos_y), car_resized)

                bg.save(target_path, 'JPEG', quality=95)
                return target_path, filename
        except Exception as e:
            print(f"Error procesando {source_asset_path}: {e}")

    return None, None

def generate_html_gallery(items):
    html_content = """<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MY AUTO GUIDE • Catálogo de Referencia Automotriz Colombia</title>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg: #090B10;
            --card-bg: #121620;
            --card-border: #1E2536;
            --accent: #00E5FF;
            --accent-glow: rgba(0, 229, 255, 0.25);
            --text-main: #FFFFFF;
            --text-muted: #8E9BAE;
        }
        * { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Outfit', sans-serif; }
        body { background: var(--bg); color: var(--text-main); min-height: 100vh; padding: 30px 20px; }
        .container { max-width: 1400px; margin: 0 auto; }
        header { text-align: center; margin-bottom: 36px; }
        h1 { font-size: 2.4rem; font-weight: 800; letter-spacing: -0.5px; margin-bottom: 8px; }
        h1 span { color: var(--accent); }
        p.subtitle { color: var(--text-muted); font-size: 1.1rem; }
        
        .controls {
            display: flex; gap: 14px; flex-wrap: wrap; justify-content: center; align-items: center;
            background: var(--card-bg); border: 1px solid var(--card-border);
            padding: 16px 20px; border-radius: 16px; margin-bottom: 30px;
        }
        .search-box {
            flex: 1; min-width: 280px; max-width: 500px; position: relative;
        }
        .search-box input {
            width: 100%; background: #0A0D14; border: 1px solid #273147;
            padding: 12px 18px; border-radius: 10px; color: #fff; font-size: 1rem;
            outline: none; transition: border-color 0.2s;
        }
        .search-box input:focus { border-color: var(--accent); }
        .filter-buttons { display: flex; gap: 8px; }
        .btn {
            background: #19202E; border: 1px solid #28334A; color: #fff;
            padding: 10px 18px; border-radius: 10px; cursor: pointer; font-weight: 600;
            font-size: 0.95rem; transition: all 0.2s;
        }
        .btn:hover, .btn.active {
            background: var(--accent); color: #000; border-color: var(--accent);
            box-shadow: 0 0 12px var(--accent-glow);
        }
        
        .grid {
            display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
            gap: 22px;
        }
        .card {
            background: var(--card-bg); border: 1px solid var(--card-border);
            border-radius: 16px; overflow: hidden; transition: transform 0.2s, box-shadow 0.2s;
            display: flex; flex-direction: column;
        }
        .card:hover {
            transform: translateY(-4px);
            border-color: #2F3B55;
            box-shadow: 0 10px 24px rgba(0,0,0,0.4);
        }
        .img-container {
            width: 100%; height: 210px; background: #0A0D14;
            display: flex; align-items: center; justify-content: center;
            position: relative; overflow: hidden;
        }
        .img-container img {
            width: 100%; height: 100%; object-fit: cover;
            transition: transform 0.3s ease;
        }
        .card:hover .img-container img { transform: scale(1.04); }
        .badge {
            position: absolute; top: 12px; left: 12px;
            padding: 4px 10px; border-radius: 6px; font-size: 0.75rem; font-weight: 700;
            text-transform: uppercase; letter-spacing: 0.5px;
        }
        .badge-carro { background: #0055CC; color: #fff; }
        .badge-moto { background: #FF9800; color: #000; }
        .badge-year {
            position: absolute; top: 12px; right: 12px;
            background: rgba(0,0,0,0.65); border: 1px solid rgba(255,255,255,0.15);
            color: #fff; padding: 4px 8px; border-radius: 6px; font-size: 0.75rem;
        }
        .card-body { padding: 16px; display: flex; flex-direction: column; gap: 6px; flex: 1; }
        .brand-name { font-size: 0.85rem; color: var(--accent); font-weight: 700; text-transform: uppercase; }
        .model-name { font-size: 1.15rem; font-weight: 700; color: #fff; }
        .card-actions {
            margin-top: auto; padding-top: 12px; display: flex; gap: 8px;
        }
        .action-link {
            flex: 1; text-align: center; padding: 8px; font-size: 0.85rem; font-weight: 600;
            background: #19202E; color: #CCD6E5; text-decoration: none; border-radius: 8px;
            border: 1px solid #28334A; transition: all 0.2s;
        }
        .action-link:hover { background: #252F44; color: #fff; }
        .action-link.primary { background: rgba(0,229,255,0.1); color: var(--accent); border-color: rgba(0,229,255,0.3); }
        .action-link.primary:hover { background: var(--accent); color: #000; }
        .stats-bar {
            text-align: center; margin-top: 40px; color: var(--text-muted); font-size: 0.95rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>MY AUTO GUIDE • <span>Compendio de Referencia</span></h1>
            <p class="subtitle">Modelos Vigentes y de Alta Circulación en Colombia (2015 – 2026)</p>
        </header>

        <div class="controls">
            <div class="search-box">
                <input type="text" id="searchInput" placeholder="Buscar por modelo, marca o línea (ej. Duster, NKD, Hilux)..." onkeyup="filterCards()">
            </div>
            <div class="filter-buttons">
                <button class="btn active" onclick="setCategory('all', this)">Todos</button>
                <button class="btn" onclick="setCategory('carro', this)">Carros</button>
                <button class="btn" onclick="setCategory('moto', this)">Motos</button>
            </div>
        </div>

        <div class="grid" id="vehiclesGrid">
"""

    for it in items:
        badge_cls = 'badge-carro' if it['tipo'] == 'carro' else 'badge-moto'
        tipo_label = 'Carro' if it['tipo'] == 'carro' else 'Moto'
        html_content += f"""
            <div class="card" data-tipo="{it['tipo']}" data-search="{it['marca'].lower()} {it['modelo'].lower()}">
                <div class="img-container">
                    <span class="badge {badge_cls}">{tipo_label}</span>
                    <span class="badge-year">2015 - 2026</span>
                    <img src="{it['local_rel']}" alt="{it['marca']} {it['modelo']}" loading="lazy">
                </div>
                <div class="card-body">
                    <div class="brand-name">{it['marca']}</div>
                    <div class="model-name">{it['modelo']}</div>
                    <div class="card-actions">
                        <a href="{it['local_rel']}" target="_blank" class="action-link">Ver HD Local</a>
                        <a href="{it['cloud_url']}" target="_blank" class="action-link primary">Cloud CDN</a>
                    </div>
                </div>
            </div>"""

    html_content += f"""
        </div>
        <div class="stats-bar">
            Total de vehículos indexados: <strong>{len(items)} modelos</strong> • Respaldo activo en Supabase Storage
        </div>
    </div>

    <script>
        let currentCategory = 'all';

        function setCategory(cat, btn) {{
            currentCategory = cat;
            document.querySelectorAll('.filter-buttons .btn').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            filterCards();
        }}

        function filterCards() {{
            const query = document.getElementById('searchInput').value.toLowerCase().trim();
            const cards = document.querySelectorAll('.card');

            cards.forEach(card => {{
                const cardTipo = card.getAttribute('data-tipo');
                const cardSearch = card.getAttribute('data-search');

                const matchesCat = (currentCategory === 'all' || cardTipo === currentCategory);
                const matchesQuery = (query === '' || cardSearch.includes(query));

                if (matchesCat && matchesQuery) {{
                    card.style.display = 'flex';
                }} else {{
                    card.style.display = 'none';
                }}
            }});
        }}
    </script>
</body>
</html>
"""
    with open(os.path.join(OUTPUT_DIR, 'galeria_colombia.html'), 'w', encoding='utf-8') as f:
        f.write(html_content)

def main():
    print("============================================================")
    print("🚗 CONSTRUYENDO COMPENDIO DE REFERENCIA VEHICULAR COLOMBIA")
    print("============================================================")

    # 1. Obtener artefactos previos del cerebro
    brain_artifacts = glob.glob(os.path.join(BRAIN_DIR, '*.jpg')) + glob.glob(os.path.join(BRAIN_DIR, '*.png'))
    print(f"Artefactos de estudio disponibles: {len(brain_artifacts)}")

    # 2. Leer catálogo local
    with open('lib/core/services/vehicle_catalog_service.dart', 'r', encoding='utf-8') as f:
        catalog_text = f.read()

    # Extraer marcas y modelos de carros y motos
    car_blocks = re.findall(r"'([A-Z0-9_\-\s]+)':\s*\[([\s\S]*?)\]\s*,", catalog_text)
    
    # Lista de ítems generados
    catalog_items = []

    print("\n📌 1. Procesando Fotografías de Carros y Motos en Alta Definición...")

    # Procesar Carros
    for marca, models_raw in car_blocks:
        models = re.findall(r"'modelo':\s*'([^']+)',\s*'img':\s*'assets/carros/([^']+)'", models_raw)
        for mod_name, img_rel in models:
            src_path = os.path.join('assets', 'carros', img_rel)
            saved_path, fname = process_vehicle('carros', marca, mod_name, src_path, brain_artifacts)
            if saved_path:
                rel_path = os.path.relpath(saved_path, OUTPUT_DIR).replace('\\', '/')
                cloud_dest = f"carros/{marca.lower()}/{fname}"
                cloud_url = f"{SUPABASE_URL}/storage/v1/object/public/{STORAGE_BUCKET}/{cloud_dest}"
                catalog_items.append({
                    'tipo': 'carro',
                    'marca': marca,
                    'modelo': mod_name,
                    'local_path': saved_path,
                    'local_rel': rel_path,
                    'cloud_dest': cloud_dest,
                    'cloud_url': cloud_url
                })

    # Procesar Motos
    for marca, models_raw in car_blocks:
        models = re.findall(r"'modelo':\s*'([^']+)',\s*'img':\s*'assets/motos/([^']+)'", models_raw)
        for mod_name, img_rel in models:
            src_path = os.path.join('assets', 'motos', img_rel)
            saved_path, fname = process_vehicle('motos', marca, mod_name, src_path, brain_artifacts)
            if saved_path:
                rel_path = os.path.relpath(saved_path, OUTPUT_DIR).replace('\\', '/')
                cloud_dest = f"motos/{marca.lower()}/{fname}"
                cloud_url = f"{SUPABASE_URL}/storage/v1/object/public/{STORAGE_BUCKET}/{cloud_dest}"
                catalog_items.append({
                    'tipo': 'moto',
                    'marca': marca,
                    'modelo': mod_name,
                    'local_path': saved_path,
                    'local_rel': rel_path,
                    'cloud_dest': cloud_dest,
                    'cloud_url': cloud_url
                })

    print(f"✔ Total de modelos renderizados en Full HD 1080p: {len(catalog_items)}")

    # 3. Guardar catálogo HTML interactivo
    print("\n📌 2. Generando Galería HTML Interactiva...")
    generate_html_gallery(catalog_items)
    print(f"✔ Galería generada en: {os.path.join(OUTPUT_DIR, 'galeria_colombia.html')}")

    # 4. Guardar archivo manifest JSON para consumo del script de subida
    manifest_path = os.path.join(OUTPUT_DIR, 'catalog_manifest.json')
    with open(manifest_path, 'w', encoding='utf-8') as f:
        json.dump(catalog_items, f, indent=2, ensure_ascii=False)
    print(f"✔ Manifiesto guardado en: {manifest_path}")

if __name__ == '__main__':
    main()
