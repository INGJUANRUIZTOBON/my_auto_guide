import re
import os
from PIL import Image

with open('lib/core/services/vehicle_catalog_service.dart', 'r', encoding='utf-8') as f:
    text = f.read()

imgs = re.findall(r"'(assets/[^']+)'", text)
missing = []
for p in imgs:
    if not os.path.exists(p):
        missing.append(p)
    else:
        with Image.open(p) as im:
            if im.mode != 'RGBA':
                print(f"Warning: {p} is {im.mode}")

print(f"Total catalog assets checked: {len(imgs)}")
print(f"Missing files: {len(missing)}")
if missing:
    for m in missing:
        print(f"  MISSING: {m}")
else:
    print("✔ 100% of referenced catalog assets exist on disk and are verified!")
