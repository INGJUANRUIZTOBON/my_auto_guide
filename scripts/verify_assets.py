import os
import glob
from PIL import Image

patterns = [
    'assets/motos/**/*.png',
    'assets/carros/**/*.png',
    'assets/logos/**/*.png'
]

files = []
for p in patterns:
    files.extend(glob.glob(p, recursive=True))

print(f"Total image files scanned on disk: {len(files)}")
non_rgba = []
suspicious_opacity = []

for f in files:
    try:
        with Image.open(f) as im:
            if im.mode != 'RGBA':
                non_rgba.append((f, im.mode))
            else:
                w, h = im.size
                alpha = im.split()[3]
                opaque_pixels = sum(1 for p in alpha.getdata() if p > 250)
                total_pixels = w * h
                pct_opaque = (opaque_pixels / total_pixels) * 100
                # If an image is more than 98% opaque, it probably has an opaque background
                if pct_opaque > 98.0:
                    suspicious_opacity.append((f, pct_opaque, w, h))
    except Exception as e:
        print(f"Error reading {f}: {e}")

print(f"Non-RGBA files on disk: {len(non_rgba)}")
print(f"Suspicious files with > 98% opaque pixels: {len(suspicious_opacity)}")
for f, pct, w, h in suspicious_opacity:
    print(f"  {f} ({w}x{h}): {pct:.1f}% opaque")
