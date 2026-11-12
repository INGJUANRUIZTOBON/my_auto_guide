import os
import glob
from PIL import Image

def convert_all_to_rgba():
    patterns = [
        'assets/motos/**/*.png',
        'assets/carros/**/*.png',
        'assets/logos/**/*.png'
    ]
    
    files = []
    for p in patterns:
        files.extend(glob.glob(p, recursive=True))
        
    print(f'Analizando {len(files)} imágenes en assets...')
    converted = 0
    already_rgba = 0
    
    for f in files:
        try:
            with Image.open(f) as img:
                if img.mode != 'RGBA':
                    rgba = img.convert('RGBA')
                    rgba.save(f, format='PNG', optimize=True)
                    converted += 1
                    print(f'✔ Convertido a RGBA transparente: {f} (era {img.mode})')
                else:
                    already_rgba += 1
        except Exception as e:
            print(f'❌ Error procesando {f}: {e}')
            
    print(f'\nResumen final:')
    print(f'  Total archivos analizados: {len(files)}')
    print(f'  Archivos convertidos a RGBA con transparencia activa: {converted}')
    print(f'  Archivos que ya eran RGBA: {already_rgba}')

if __name__ == '__main__':
    convert_all_to_rgba()
