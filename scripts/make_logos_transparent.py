import os
from PIL import Image

opaque_files = [
  'assets/logos/abbott-detroit.png', 'assets/logos/alta.png', 'assets/logos/aro.png', 'assets/logos/austin.png',
  'assets/logos/autobacs.png', 'assets/logos/bizzarrini.png', 'assets/logos/corre-la-licorne.png', 'assets/logos/dartz.png',
  'assets/logos/diatto.png', 'assets/logos/dkw.png', 'assets/logos/elfin.png', 'assets/logos/englon.png',
  'assets/logos/eterniti.png', 'assets/logos/fioravanti.png', 'assets/logos/ford-mustang.png', 'assets/logos/fpv.png',
  'assets/logos/franklin.png', 'assets/logos/genesis.png', 'assets/logos/hillman.png',
  'assets/logos/hispano-suiza.png', 'assets/logos/hupmobile.png', 'assets/logos/isdera.png', 'assets/logos/jawa.png',
  'assets/logos/jensen.png', 'assets/logos/jetour.png', 'assets/logos/kaiser.png', 'assets/logos/lada.png',
  'assets/logos/marcos.png', 'assets/logos/maybach.png', 'assets/logos/morgan.png', 'assets/logos/morris.png',
  'assets/logos/oldsmobile.png', 'assets/logos/omoda.png', 'assets/logos/pgo.png', 'assets/logos/pierce-arrow.png',
  'assets/logos/saturn.png', 'assets/logos/vandenbrink.png',
  'assets/logos/wanderer.png', 'assets/logos/zastava.png', 'assets/logos/zenvo.png'
]

converted = 0
for path in opaque_files:
    if not os.path.exists(path):
        continue
    with Image.open(path) as img:
        rgba = img.convert('RGBA')
        datas = rgba.getdata()
        newData = []
        # Target white or near-white background (r > 240, g > 240, b > 240)
        for item in datas:
            if item[0] >= 242 and item[1] >= 242 and item[2] >= 242:
                newData.append((255, 255, 255, 0))
            else:
                newData.append(item)
        rgba.putdata(newData)
        rgba.save(path, 'PNG', optimize=True)
        converted += 1
        print(f"✔ Transparentado: {path}")

print(f"Total logos transparentados con éxito: {converted}")
