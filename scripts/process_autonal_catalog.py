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
        current_brand = b_match.group(1).upper().strip()
        existing_models_by_brand[current_brand] = set()
    m_match = re.search(r'\'modelo\':\s*\'([^\']+)\'', line)
    if m_match and current_brand:
        existing_models_by_brand[current_brand].add(m_match.group(1).upper().strip())

def clean_brand(b):
    b = b.upper().strip()
    if b == 'MERCEDES BENZ': return 'MERCEDES-BENZ'
    if b == 'CITROEN': return 'CITROËN'
    return b

def extract_clean_model(brand, model_raw, folder):
    m = f"{model_raw} {folder}".upper()

    line_rules = [
        # Audi
        ('AUDI', r'\bQ5\b', 'Q5'),
        ('AUDI', r'\bQ3\b', 'Q3'),
        ('AUDI', r'\bS3\b', 'S3'),
        
        # BMW
        ('BMW', r'\bX2\b', 'X2'),
        ('BMW', r'\bX5\b', 'X5'),
        ('BMW', r'\b218I\b', '218i Gran Coupé'),
        ('BMW', r'\b530I\b', '530i Sedan'),
        
        # BYD
        ('BYD', r'\bSEAGULL\b', 'Seagull'),
        ('BYD', r'\bQIN PLUS|QIN\b', 'Qin Plus'),
        ('BYD', r'\bSONG PRO\b', 'Song Pro'),
        ('BYD', r'\bSONG PLUS\b', 'Song Plus'),
        ('BYD', r'\bYUAN PLUS|YUAN\b', 'Yuan Plus'),
        ('BYD', r'\bDOLPHIN\b', 'Dolphin Mini'),
        
        # Changan
        ('CHANGAN', r'\bCS-55|CS55\b', 'CS-55 Plus'),
        ('CHANGAN', r'\bCS-35|CS35\b', 'CS-35 Plus'),
        
        # Chery
        ('CHERY', r'\bEQ7\b', 'EQ7'),
        ('CHERY', r'\bTIGGO 4|TIGGO4\b', 'Tiggo 4'),
        ('CHERY', r'\bTIGGO 7|TIGGO7\b', 'Tiggo 7'),
        
        # Chevrolet
        ('CHEVROLET', r'\bCRUZE\b', 'Cruze'),
        ('CHEVROLET', r'\bJOY\b', 'Joy'),
        ('CHEVROLET', r'\bEQUINOX\b', 'Equinox'),
        ('CHEVROLET', r'\bMONTANA\b', 'Montana'),
        ('CHEVROLET', r'\bONIX\b', 'Onix'),
        ('CHEVROLET', r'\bTRACKER\b', 'Tracker'),
        ('CHEVROLET', r'\bSPARK\b', 'Spark'),
        
        # Citroën
        ('CITROËN', r'\bC3 AIRCROSS\b', 'C3 Aircross'),
        ('CITROËN', r'\bC3\b', 'C3'),
        ('CITROËN', r'\bC5 AIRCROSS\b', 'C5 Aircross'),
        
        # Cupra
        ('CUPRA', r'\bFORMENTOR\b', 'Formentor'),
        
        # Deepal
        ('DEEPAL', r'\bS07\b', 'S07'),
        
        # Ford
        ('FORD', r'\bESCAPE\b', 'Escape'),
        ('FORD', r'\bRANGER\b', 'Ranger'),
        ('FORD', r'\bFIESTA\b', 'Fiesta'),
        ('FORD', r'\bBRONCO SPORT\b', 'Bronco Sport'),
        ('FORD', r'\bBRONCO\b', 'Bronco'),
        ('FORD', r'\bECOSPORT\b', 'Ecosport'),
        ('FORD', r'\bEDGE\b', 'Edge'),
        ('FORD', r'\bF-150|F150\b', 'F-150'),
        ('FORD', r'\bMAVERICK\b', 'Maverick'),
        
        # Haval
        ('HAVAL', r'\bH6\b', 'H6'),
        ('HAVAL', r'\bJOLION\b', 'Jolion'),
        
        # Honda
        ('HONDA', r'\bCR-V|CRV\b', 'CR-V'),
        ('HONDA', r'\bHR-V|HRV\b', 'HR-V'),
        ('HONDA', r'\bWR-V|WRV\b', 'WR-V'),
        ('HONDA', r'\bCIVIC\b', 'Civic'),
        ('HONDA', r'\bCITY\b', 'City'),
        
        # Hyundai
        ('HYUNDAI', r'\bKONA\b', 'Kona'),
        ('HYUNDAI', r'\bSTARIA\b', 'Staria'),
        ('HYUNDAI', r'\bGRAVITI\b', 'HB20 Graviti'),
        ('HYUNDAI', r'\bCRETA\b', 'Creta'),
        ('HYUNDAI', r'\bTUCSON\b', 'Tucson'),
        
        # Jeep
        ('JEEP', r'\bCOMPASS\b', 'Compass'),
        ('JEEP', r'\bRENEGADE\b', 'Renegade'),
        ('JEEP', r'\bWRANGLER\b', 'Wrangler Unlimited 4x4'),
        
        # JMC
        ('JMC', r'\bJMEV|EV3|JMEV2\b', 'JMEV EV3'),
        ('JMC', r'\bVIGUS\b', 'Vigus Pro'),
        
        # Kia
        ('KIA', r'\bSOLUTO\b', 'Soluto'),
        ('KIA', r'\bPICANTO\b', 'Picanto'),
        ('KIA', r'\bRIO\b', 'Rio'),
        ('KIA', r'\bSPORTAGE\b', 'Sportage'),
        ('KIA', r'\bSELTOS\b', 'Seltos'),
        ('KIA', r'\bSONET\b', 'Sonet'),
        ('KIA', r'\bK3 CROSS\b', 'K3 Cross'),
        ('KIA', r'\bK3\b', 'K3'),
        ('KIA', r'\bNIRO\b', 'Niro'),
        ('KIA', r'\bCARENS\b', 'Carens'),
        ('KIA', r'\bTASMAN\b', 'Tasman'),
        
        # Mini
        ('MINI', r'\bCOOPER\b', 'Cooper'),
        ('MINI', r'\bCOUNTRYMAN\b', 'Countryman'),
        
        # Mitsubishi
        ('MITSUBISHI', r'\bASX\b', 'ASX'),
        ('MITSUBISHI', r'\bECLIPSE CROSS\b', 'Eclipse Cross'),
        
        # Opel
        ('OPEL', r'\bROCKS\b', 'Rocks-e'),
        ('OPEL', r'\bCORSA\b', 'Corsa'),
        ('OPEL', r'\bMOKKA\b', 'Mokka'),
        
        # Renault
        ('RENAULT', r'\bARKANA\b', 'Arkana'),
        ('RENAULT', r'\bCAPTUR\b', 'Captur'),
        ('RENAULT', r'\bDUSTER\b', 'Duster'),
        
        # Seat
        ('SEAT', r'\bARONA\b', 'Arona'),
        ('SEAT', r'\bIBIZA\b', 'Ibiza'),
        ('SEAT', r'\bATECA\b', 'Ateca'),
        ('SEAT', r'\bTARRACO\b', 'Tarraco'),
        
        # Suzuki
        ('SUZUKI', r'\bBALENO\b', 'Baleno'),
        ('SUZUKI', r'\bFRONX\b', 'Fronx'),
        ('SUZUKI', r'\bGRAND VITARA\b', 'Grand Vitara'),
        ('SUZUKI', r'\bVITARA\b', 'Vitara'),
        ('SUZUKI', r'\bSWIFT\b', 'Swift'),
        ('SUZUKI', r'\bJIMNY\b', 'Jimny'),
        
        # Tesla
        ('TESLA', r'\bMODEL Y\b', 'Model Y'),
        ('TESLA', r'\bMODEL 3\b', 'Model 3'),
        
        # Toyota
        ('TOYOTA', r'\bFORTUNER|SW4\b', 'Fortuner'),
        ('TOYOTA', r'\bCOROLLA CROSS\b', 'Corolla Cross'),
        ('TOYOTA', r'\bCOROLLA\b', 'Corolla'),
        ('TOYOTA', r'\bYARIS CROSS\b', 'Yaris Cross'),
        ('TOYOTA', r'\bYARIS SPORT|YARIS\b', 'Yaris'),
        ('TOYOTA', r'\bHILUX\b', 'Hilux'),
        ('TOYOTA', r'\bPRADO\b', 'Prado'),
        
        # Volkswagen
        ('VOLKSWAGEN', r'\bVOYAGE\b', 'Voyage'),
        ('VOLKSWAGEN', r'\bGOLF\b', 'Golf'),
        ('VOLKSWAGEN', r'\bJETTA\b', 'Jetta'),
        ('VOLKSWAGEN', r'\bVIRTUS\b', 'Virtus'),
        ('VOLKSWAGEN', r'\bGOL\b', 'Gol'),
        ('VOLKSWAGEN', r'\bT-CROSS|TCROSS\b', 'T-Cross'),
    ]

    for b_pat, pat, res in line_rules:
        if brand == b_pat and re.search(pat, m):
            return res

    cleaned = re.sub(r'\b(AUT|MHEV|PHEV|BEV|HEV|TURBO|SPORT|STYLE|TRENDLINE|COMFORTLINE|XCELLENT|AMBITION|TFSI|4X4|5P|7 PAS|TIPTRONIC|GS|DM-I|LUXURY|LT|LTZ|PREMIER|SHINE|DYNAMIC|MAX|TITANIUM|LIMITED|PREMIUM|PANEL|LONGITUDE|CLASSIC|TECHNO|FR|GLX|GL|SEG|XEI|XLS|XS|R-DESIGN|ULTIMATE|DARK)\b', '', m)
    tokens = [t for t in cleaned.split() if t != brand and not re.match(r'^\d+(\.\d+)?$', t) and not re.match(r'^\d{4}$', t)]
    return ' '.join(tokens[:2]).title() if tokens else 'Modelo'

base = 'D:/Descargas/autnal/autnal'
candidates = {}
skipped_existing = []

for b in sorted(os.listdir(base)):
    b_path = os.path.join(base, b)
    if not os.path.isdir(b_path): continue
    brand_clean = clean_brand(b)
    brand_existing = existing_models_by_brand.get(brand_clean, set())

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
        line = extract_clean_model(brand_clean, raw_model, s)
        full_model = f"{brand_clean.title()} {line}"

        # Comprobar si ya existe con exactitud de palabra
        def is_in_existing(l, existing_set):
            l_up = l.upper().strip()
            for em in existing_set:
                if l_up == em:
                    return True
                pattern = r'\b' + re.escape(l_up) + r'\b'
                if re.search(pattern, em):
                    if l_up == 'C3' and 'AIRCROSS' in em: continue
                    if l_up == 'GOL' and 'GOLF' in em: continue
                    return True
            return False

        if is_in_existing(line, brand_existing):
            skipped_existing.append((brand_clean, line, raw_model))
            continue

        key = (brand_clean, line)
        if key not in candidates:
            candidates[key] = {
                'brand': brand_clean,
                'line': line,
                'full_model': full_model,
                'folder': s_path,
                'image': os.path.join(s_path, img_files[0]),
                'info': info
            }

print(f"Skipped because already in catalog: {len(skipped_existing)}")
print(f"TOTAL TRULY NEW UNIQUE VEHICLE LINES: {len(candidates)}")
print("=" * 70)
for (b, l), c in sorted(candidates.items()):
    print(f"[{b:<14}] Línea: {l:<20} | Modelo: {c['full_model']:<25}")

# Exportar lista depurada
with open('scripts/autonal_selected_models.json', 'w', encoding='utf-8') as out:
    json.dump(list(candidates.values()), out, indent=2, ensure_ascii=False)
