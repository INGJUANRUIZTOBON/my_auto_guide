import os
import json

with open('scripts/autonal_selected_models.json', 'r', encoding='utf-8') as f:
    models = json.load(f)

valid_lines = [
    ('AUDI', 'Q5'),
    ('BMW', 'X2'),
    ('BYD', 'Qin Plus'),
    ('BYD', 'Seagull'),
    ('BYD', 'Song Pro'),
    ('BYD', 'Yuan Plus'),
    ('CHANGAN', 'CS-55 Plus'),
    ('CHERY', 'EQ7'),
    ('CHERY', 'Tiggo 4'),
    ('CHEVROLET', 'Cruze'),
    ('CHEVROLET', 'Joy'),
    ('CITROËN', 'C3 Aircross'),
    ('DEEPAL', 'S07'),
    ('FORD', 'Fiesta'),
    ('HAVAL', 'H6'),
    ('HONDA', 'CR-V'),
    ('HONDA', 'HR-V'),
    ('HYUNDAI', 'HB20 Graviti'),
    ('HYUNDAI', 'Kona'),
    ('HYUNDAI', 'Staria'),
    ('JEEP', 'Compass'),
    ('JEEP', 'Renegade'),
    ('JMC', 'JMEV EV3'),
    ('KIA', 'Soluto'),
    ('MINI', 'Cooper'),
    ('MITSUBISHI', 'ASX'),
    ('OPEL', 'Rocks-e'),
    ('RENAULT', 'Arkana'),
    ('SEAT', 'Arona'),
    ('SEAT', 'Ibiza'),
    ('SUZUKI', 'Baleno'),
    ('SUZUKI', 'Fronx'),
    ('TESLA', 'Model Y'),
    ('VOLKSWAGEN', 'Golf'),
    ('VOLKSWAGEN', 'Voyage')
]

filtered = []
seen_keys = set()
for m in models:
    key = (m['brand'], m['line'])
    if key in valid_lines and key not in seen_keys:
        seen_keys.add(key)
        filtered.append(m)

print(f'Total verified clean models to process: {len(filtered)}')
for m in filtered:
    exists = os.path.exists(m['image'])
    sz = os.path.getsize(m['image']) if exists else 0
    fn = os.path.basename(m['image'])
    print(f"[{m['brand']:12}] {m['line']:15} -> {fn} (Exists: {exists}, {sz//1024} KB)")

with open('scripts/autonal_final_35.json', 'w', encoding='utf-8') as f:
    json.dump(filtered, f, indent=2, ensure_ascii=False)
