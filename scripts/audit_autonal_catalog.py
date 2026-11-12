import os
import json
import re

# 1. Cargar el catálogo existente de Flutter
with open('lib/core/services/vehicle_catalog_service.dart', 'r', encoding='utf-8') as f:
    text = f.read()

start = text.find('_carCatalog = {')
end = text.find('final Map<String, String> _carLogos')
block = text[start:end]

existing_models_by_brand = {}
current_brand = None
for line in block.splitlines():
    b_match = re.search(r'\'([^\']+)\':\s*\[', line)
    if b_match:
        current_brand = b_match.group(1).upper()
        existing_models_by_brand[current_brand] = set()
    m_match = re.search(r'\'modelo\':\s*\'([^\']+)\'', line)
    if m_match and current_brand:
        existing_models_by_brand[current_brand].add(m_match.group(1).upper())

def clean_brand(b):
    b = b.upper().strip()
    if b == 'MERCEDES BENZ': return 'MERCEDES-BENZ'
    if b == 'CITROEN': return 'CITROËN'
    return b

def extract_model_line(brand, model_raw, folder):
    m = model_raw.upper().strip()
    b = brand.upper().strip()
    if m.startswith(b):
        m = m[len(b):].strip()

    patterns = [
        # Toyota
        (r'\b(COROLLA CROSS)\b', 'Corolla Cross'),
        (r'\b(COROLLA)\b', 'Corolla'),
        (r'\b(FORTUNER SW4|FORTUNER|SW4)\b', 'Fortuner SW4'),
        (r'\b(YARIS CROSS)\b', 'Yaris Cross'),
        (r'\b(YARIS SPORT)\b', 'Yaris Sport'),
        (r'\b(YARIS)\b', 'Yaris'),
        (r'\b(HILUX)\b', 'Hilux'),
        (r'\b(PRADO)\b', 'Prado'),
        (r'\b(RAV4)\b', 'RAV4'),
        (r'\b(LAND CRUISER)\b', 'Land Cruiser'),
        # Chevrolet
        (r'\b(TRACKER)\b', 'Tracker'),
        (r'\b(ONIX)\b', 'Onix'),
        (r'\b(SPARK BEV|SPARK EV|SPARK)\b', 'Spark'),
        (r'\b(SAIL)\b', 'Sail'),
        (r'\b(CRUZE)\b', 'Cruze'),
        (r'\b(EQUINOX)\b', 'Equinox'),
        (r'\b(JOY)\b', 'Joy'),
        (r'\b(MONTANA)\b', 'Montana'),
        (r'\b(CAPTIVA)\b', 'Captiva'),
        (r'\b(TRAILBLAZER)\b', 'Trailblazer'),
        (r'\b(TAHOE)\b', 'Tahoe'),
        (r'\b(CAMARO)\b', 'Camaro'),
        # Renault
        (r'\b(DUSTER)\b', 'Duster'),
        (r'\b(STEPWAY)\b', 'Stepway'),
        (r'\b(SANDERO)\b', 'Sandero'),
        (r'\b(LOGAN)\b', 'Logan'),
        (r'\b(KWID)\b', 'Kwid'),
        (r'\b(KOLEOS)\b', 'Koleos'),
        (r'\b(OROCH)\b', 'Oroch'),
        (r'\b(CAPTUR)\b', 'Captur'),
        (r'\b(KANGOO)\b', 'Kangoo'),
        (r'\b(MEGANE)\b', 'Megane'),
        (r'\b(CLIO)\b', 'Clio'),
        # Kia
        (r'\b(PICANTO)\b', 'Picanto'),
        (r'\b(RIO)\b', 'Rio'),
        (r'\b(SPORTAGE)\b', 'Sportage'),
        (r'\b(SELTOS)\b', 'Seltos'),
        (r'\b(SONET)\b', 'Sonet'),
        (r'\b(CERATO)\b', 'Cerato'),
        (r'\b(SORENTO)\b', 'Sorento'),
        (r'\b(K3 CROSS)\b', 'K3 Cross'),
        (r'\b(K3)\b', 'K3'),
        (r'\b(NIRO)\b', 'Niro'),
        (r'\b(CARENS)\b', 'Careens'),
        (r'\b(TASMAN)\b', 'Tasman'),
        # Mazda
        (r'\b(MAZDA 2| 2 )\b', '2'),
        (r'\b(MAZDA 3| 3 )\b', '3'),
        (r'\b(CX-30|CX30)\b', 'CX-30'),
        (r'\b(CX-5|CX5)\b', 'CX-5'),
        (r'\b(CX-50|CX50)\b', 'CX-50'),
        (r'\b(CX-60|CX60)\b', 'CX-60'),
        (r'\b(CX-90|CX90)\b', 'CX-90'),
        (r'\b(CX-9|CX9)\b', 'CX-9'),
        (r'\b(CX-3|CX3)\b', 'CX-3'),
        # Nissan
        (r'\b(VERSA)\b', 'Versa'),
        (r'\b(KICKS)\b', 'Kicks'),
        (r'\b(SENTRA)\b', 'Sentra'),
        (r'\b(FRONTIER)\b', 'Frontier'),
        (r'\b(MARCH)\b', 'March'),
        (r'\b(QASHQAI)\b', 'Qashqai'),
        (r'\b(X-TRAIL|X TRAIL)\b', 'X-Trail'),
        # Volkswagen
        (r'\b(GOL)\b', 'Gol'),
        (r'\b(VOYAGE)\b', 'Voyage'),
        (r'\b(T-CROSS|TCROSS)\b', 'T-Cross'),
        (r'\b(TAOS)\b', 'Taos'),
        (r'\b(NIVUS)\b', 'Nivus'),
        (r'\b(POLO)\b', 'Polo'),
        (r'\b(JETTA)\b', 'Jetta'),
        (r'\b(VIRTUS)\b', 'Virtus'),
        (r'\b(AMAROK)\b', 'Amarok'),
        (r'\b(TIGUAN)\b', 'Tiguan'),
        (r'\b(GOLF)\b', 'Golf'),
        # Suzuki
        (r'\b(SWIFT)\b', 'Swift'),
        (r'\b(GRAND VITARA)\b', 'Grand Vitara'),
        (r'\b(VITARA)\b', 'Vitara'),
        (r'\b(JIMNY)\b', 'Jimny'),
        (r'\b(BALENO CROSS|BALENO)\b', 'Baleno'),
        (r'\b(FRONX)\b', 'Fronx'),
        (r'\b(S-CROSS|SCROSS)\b', 'S-Cross'),
        # BYD
        (r'\b(SEAGULL)\b', 'Seagull'),
        (r'\b(DOLPHIN)\b', 'Dolphin'),
        (r'\b(YUAN PLUS|YUAN)\b', 'Yuan Plus'),
        (r'\b(SONG PRO|SONG PLUS|SONG)\b', 'Song Pro'),
        (r'\b(QIN PLUS|QIN)\b', 'Qin Plus'),
        (r'\b(TANG)\b', 'Tang'),
        (r'\b(HAN)\b', 'Han'),
        # Tesla
        (r'\b(MODEL 3)\b', 'Model 3'),
        (r'\b(MODEL Y)\b', 'Model Y'),
        (r'\b(MODEL S)\b', 'Model S'),
        (r'\b(MODEL X)\b', 'Model X'),
        # Audi
        (r'\b(Q3)\b', 'Q3'),
        (r'\b(Q5)\b', 'Q5'),
        (r'\b(S3)\b', 'S3'),
        (r'\b(A3)\b', 'A3'),
        (r'\b(A4)\b', 'A4'),
        # BMW
        (r'\b(X2)\b', 'X2'),
        (r'\b(X3)\b', 'X3'),
        (r'\b(X5)\b', 'X5'),
        (r'\b(218I)\b', '218i Gran Coupé'),
        (r'\b(530I)\b', '530i Sedan'),
        # Citroën
        (r'\b(C3 AIRCROSS)\b', 'C3 Aircross'),
        (r'\b(C3)\b', 'C3'),
        (r'\b(C5 AIRCROSS)\b', 'C5 Aircross'),
        # Cupra & Seat
        (r'\b(FORMENTOR)\b', 'Formentor'),
        (r'\b(ATECA)\b', 'Ateca'),
        (r'\b(IBIZA)\b', 'Ibiza'),
        (r'\b(LEON)\b', 'Leon'),
        (r'\b(TARRACO)\b', 'Tarraco'),
        # Volvo
        (r'\b(XC40)\b', 'XC40 Recharge'),
        (r'\b(XC60)\b', 'XC60 Recharge'),
        (r'\b(EC40)\b', 'EC40 Recharge Eléctrico'),
        # Changan, Chery, Deepal, Haval, Honda, JMC, Opel
        (r'\b(CS-55|CS55)\b', 'CS-55 Plus'),
        (r'\b(CS-35|CS35)\b', 'CS-35 Plus'),
        (r'\b(EQ7)\b', 'EQ7'),
        (r'\b(TIGGO 4|TIGGO4)\b', 'Tiggo 4'),
        (r'\b(TIGGO 7|TIGGO7)\b', 'Tiggo 7'),
        (r'\b(S07)\b', 'S07'),
        (r'\b(JOLION)\b', 'Jolion'),
        (r'\b(H6)\b', 'H6'),
        (r'\b(CR-V|CRV)\b', 'CR-V'),
        (r'\b(HR-V|HRV)\b', 'HR-V'),
        (r'\b(WR-V|WRV)\b', 'WR-V'),
        (r'\b(CIVIC)\b', 'Civic'),
        (r'\b(CITY)\b', 'City'),
        (r'\b(VIGUS)\b', 'Vigus Pro'),
        (r'\b(CORSA)\b', 'Corsa'),
        (r'\b(MOKKA)\b', 'Mokka'),
        (r'\b(CROSSLAND)\b', 'Crossland'),
        (r'\b(GRANDLAND)\b', 'Grandland'),
    ]

    for pat, name in patterns:
        if re.search(pat, m, re.IGNORECASE) or re.search(pat, folder, re.IGNORECASE):
            return name

    tokens = m.split()
    return ' '.join(tokens[:2]).title() if len(tokens) >= 2 else (tokens[0].title() if tokens else m.title())

base = 'D:/Descargas/autnal/autnal'
candidates = {}
existing_skipped = []

for b in sorted(os.listdir(base)):
    b_path = os.path.join(base, b)
    if not os.path.isdir(b_path): continue
    brand_clean = clean_brand(b)

    for s in sorted(os.listdir(b_path)):
        s_path = os.path.join(b_path, s)
        if not os.path.isdir(s_path): continue
        files = os.listdir(s_path)
        img_files = [f for f in files if f.lower().endswith(('.jpg', '.jpeg', '.png', '.webp'))]
        if not img_files: continue

        info = {}
        if 'info.json' in files:
            with open(os.path.join(s_path, 'info.json'), 'r', encoding='utf-8') as f:
                info = json.load(f)

        raw_model = info.get('modelo', s)
        line = extract_model_line(brand_clean, raw_model, s)
        full_model_name = f'{brand_clean.title()} {line}'

        brand_models = existing_models_by_brand.get(brand_clean, set())

        # Check if already present
        already_present = False
        line_clean = line.upper().replace('-', '').replace(' ', '')
        for em in brand_models:
            em_clean = em.upper().replace('-', '').replace(' ', '')
            if line_clean in em_clean or em_clean in line_clean:
                already_present = True
                existing_skipped.append((brand_clean, line, em))
                break

        key = (brand_clean, line)
        if not already_present and key not in candidates:
            candidates[key] = {
                'brand': brand_clean,
                'line': line,
                'full_model': full_model_name,
                'folder': s_path,
                'image': os.path.join(s_path, img_files[0]),
                'info': info
            }

print(f"Skipped because already in catalog: {len(existing_skipped)}")
print(f"TRULY NEW UNIQUE MODELS FOUND: {len(candidates)}")
print("=" * 60)
for k, c in sorted(candidates.items()):
    print(f"Brand: {c['brand']:<15} | Line: {c['line']:<20} | Model: {c['full_model']}")

# Export json
with open('scripts/autonal_selected_models.json', 'w', encoding='utf-8') as out:
    json.dump(list(candidates.values()), out, indent=2, ensure_ascii=False)
