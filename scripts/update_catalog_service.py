import re

path = 'lib/core/services/vehicle_catalog_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Audi Q5
if "'Q5'" not in content:
    content = content.replace(
        "{'modelo': 'Q3', 'img': 'assets/carros/audi/audi_q3.png'},",
        "{'modelo': 'Q3', 'img': 'assets/carros/audi/audi_q3.png'},\n      {'modelo': 'Q5', 'img': 'assets/carros/audi/audi_q5.png'},"
    )

# 2. BMW X2
if "'X2'" not in content:
    content = content.replace(
        "{'modelo': 'X1', 'img': 'assets/carros/bmw/bmw_x1.png'},",
        "{'modelo': 'X1', 'img': 'assets/carros/bmw/bmw_x1.png'},\n      {'modelo': 'X2', 'img': 'assets/carros/bmw/bmw_x2.png'},"
    )

# 3. BYD Qin Plus, Seagull, Song Pro, Yuan Plus
if "'QIN PLUS'" not in content:
    content = content.replace(
        "{'modelo': 'DOLPHIN MINI', 'img': 'assets/carros/byd/dolphin_mini.png'},",
        "{'modelo': 'DOLPHIN MINI', 'img': 'assets/carros/byd/dolphin_mini.png'},\n      {'modelo': 'QIN PLUS', 'img': 'assets/carros/byd/byd_qin_plus.png'},\n      {'modelo': 'SEAGULL', 'img': 'assets/carros/byd/byd_seagull.png'},"
    )
    content = content.replace(
        "{'modelo': 'SONG PLUS', 'img': 'assets/carros/byd/song_plus.png'},",
        "{'modelo': 'SONG PLUS', 'img': 'assets/carros/byd/song_plus.png'},\n      {'modelo': 'SONG PRO', 'img': 'assets/carros/byd/byd_song_pro.png'},\n      {'modelo': 'YUAN PLUS', 'img': 'assets/carros/byd/byd_yuan_plus.png'},"
    )

# 4. Chevrolet Cruze, Joy
if "'CRUZE'" not in content:
    content = content.replace(
        "{'modelo': 'SILVERADO', 'img': 'assets/carros/chevrolet/silverado.png'},",
        "{'modelo': 'SILVERADO', 'img': 'assets/carros/chevrolet/silverado.png'},\n      {'modelo': 'CRUZE', 'img': 'assets/carros/chevrolet/chevrolet_cruze.png'},\n      {'modelo': 'JOY', 'img': 'assets/carros/chevrolet/chevrolet_joy.png'},"
    )

# 5. Citroen C3 Aircross
if "'C3 AIRCROSS'" not in content:
    content = content.replace(
        "{'modelo': 'C3', 'img': 'assets/carros/citroen/citroen_c3.png'},",
        "{'modelo': 'C3', 'img': 'assets/carros/citroen/citroen_c3.png'},\n      {'modelo': 'C3 AIRCROSS', 'img': 'assets/carros/citroen/citroen_c3_aircross.png'},"
    )

# 6. Ford Fiesta
if "'FIESTA'" not in content:
    content = content.replace(
        "{'modelo': 'MAVERICK', 'img': 'assets/carros/ford/ford_maverick.png'},",
        "{'modelo': 'MAVERICK', 'img': 'assets/carros/ford/ford_maverick.png'},\n      {'modelo': 'FIESTA', 'img': 'assets/carros/ford/ford_fiesta.png'},"
    )

# 7. Hyundai HB20 Graviti, Kona, Staria
if "'KONA'" not in content:
    content = content.replace(
        "{'modelo': 'CRETA', 'img': 'assets/carros/hyundai/hyundai_creta.png'},",
        "{'modelo': 'CRETA', 'img': 'assets/carros/hyundai/hyundai_creta.png'},\n      {'modelo': 'HB20 GRAVITI', 'img': 'assets/carros/hyundai/hyundai_hb20_graviti.png'},\n      {'modelo': 'KONA', 'img': 'assets/carros/hyundai/hyundai_kona.png'},\n      {'modelo': 'STARIA', 'img': 'assets/carros/hyundai/hyundai_staria.png'},"
    )

# 8. Jeep Compass, Renegade
if "'COMPASS'" not in content:
    content = content.replace(
        "{'modelo': 'WRANGLER UNLIMITED 4X4', 'img': 'assets/carros/jeep/jeep_wrangler_unlimited_4x4.png'},",
        "{'modelo': 'WRANGLER UNLIMITED 4X4', 'img': 'assets/carros/jeep/jeep_wrangler_unlimited_4x4.png'},\n      {'modelo': 'COMPASS', 'img': 'assets/carros/jeep/jeep_compass.png'},\n      {'modelo': 'RENEGADE', 'img': 'assets/carros/jeep/jeep_renegade.png'},"
    )

# 9. Kia Soluto
if "'SOLUTO'" not in content:
    content = content.replace(
        "{'modelo': 'TASMAN', 'img': 'assets/carros/kia/kia_tasman.png'},",
        "{'modelo': 'TASMAN', 'img': 'assets/carros/kia/kia_tasman.png'},\n      {'modelo': 'SOLUTO', 'img': 'assets/carros/kia/kia_soluto.png'},"
    )

# 10. Mini Cooper
if "'COOPER'" not in content:
    content = content.replace(
        "{'modelo': 'COUNTRYMAN', 'img': 'assets/carros/mini/mini_countryman.png'},",
        "{'modelo': 'COUNTRYMAN', 'img': 'assets/carros/mini/mini_countryman.png'},\n      {'modelo': 'COOPER', 'img': 'assets/carros/mini/mini_cooper.png'},"
    )

# 11. Mitsubishi ASX
if "'ASX'" not in content:
    content = content.replace(
        "{'modelo': 'ECLIPSE CROSS', 'img': 'assets/carros/mitsubishi/mitsubishi_eclipse_cross.png'},",
        "{'modelo': 'ECLIPSE CROSS', 'img': 'assets/carros/mitsubishi/mitsubishi_eclipse_cross.png'},\n      {'modelo': 'ASX', 'img': 'assets/carros/mitsubishi/mitsubishi_asx.png'},"
    )

# 12. Renault Arkana
if "'ARKANA'" not in content:
    content = content.replace(
        "{'modelo': 'KOLEOS', 'img': 'assets/carros/renault/koleos.png'},",
        "{'modelo': 'KOLEOS', 'img': 'assets/carros/renault/koleos.png'},\n      {'modelo': 'ARKANA', 'img': 'assets/carros/renault/renault_arkana.png'},"
    )

# 13. Seat Arona, Ibiza
if "'ARONA'" not in content:
    content = content.replace(
        "{'modelo': 'TARRACO', 'img': 'assets/carros/seat/seat_tarraco.png'},",
        "{'modelo': 'TARRACO', 'img': 'assets/carros/seat/seat_tarraco.png'},\n      {'modelo': 'ARONA', 'img': 'assets/carros/seat/seat_arona.png'},\n      {'modelo': 'IBIZA', 'img': 'assets/carros/seat/seat_ibiza.png'},"
    )

# 14. Suzuki Baleno, Fronx
if "'BALENO'" not in content:
    content = content.replace(
        "{'modelo': 'GRAND VITARA', 'img': 'assets/carros/suzuki/suzuki_grand_vitara.png'},",
        "{'modelo': 'GRAND VITARA', 'img': 'assets/carros/suzuki/suzuki_grand_vitara.png'},\n      {'modelo': 'BALENO', 'img': 'assets/carros/suzuki/suzuki_baleno.png'},\n      {'modelo': 'FRONX', 'img': 'assets/carros/suzuki/suzuki_fronx.png'},"
    )

# 15. Tesla Model Y
if "'MODEL Y'" not in content:
    content = content.replace(
        "{'modelo': 'MODEL 3', 'img': 'assets/carros/tesla/tesla_model_3.png'},",
        "{'modelo': 'MODEL 3', 'img': 'assets/carros/tesla/tesla_model_3.png'},\n      {'modelo': 'MODEL Y', 'img': 'assets/carros/tesla/tesla_model_y.png'},"
    )

# 16. Volkswagen Golf, Voyage
if "'VOYAGE'" not in content:
    content = content.replace(
        "{'modelo': 'VIRTUS', 'img': 'assets/carros/volkswagen/volkswagen_virtus.png'},",
        "{'modelo': 'VIRTUS', 'img': 'assets/carros/volkswagen/volkswagen_virtus.png'},\n      {'modelo': 'GOLF', 'img': 'assets/carros/volkswagen/volkswagen_golf.png'},\n      {'modelo': 'VOYAGE', 'img': 'assets/carros/volkswagen/volkswagen_voyage.png'},"
    )

# New Brands in _carCatalog: CHANGAN, CHERY, DEEPAL, HAVAL, HONDA, JMC, OPEL
new_brands_block = """    'CHANGAN': [
      {'modelo': 'CS-55 PLUS', 'img': 'assets/carros/changan/changan_cs_55_plus.png'},
    ],
    'CHERY': [
      {'modelo': 'EQ7', 'img': 'assets/carros/chery/chery_eq7.png'},
      {'modelo': 'TIGGO 4', 'img': 'assets/carros/chery/chery_tiggo_4.png'},
    ],
    'DEEPAL': [
      {'modelo': 'S07', 'img': 'assets/carros/deepal/deepal_s07.png'},
    ],
    'HAVAL': [
      {'modelo': 'H6', 'img': 'assets/carros/haval/haval_h6.png'},
    ],
    'HONDA': [
      {'modelo': 'CR-V', 'img': 'assets/carros/honda/honda_cr_v.png'},
      {'modelo': 'HR-V', 'img': 'assets/carros/honda/honda_hr_v.png'},
    ],
    'JMC': [
      {'modelo': 'JMEV EV3', 'img': 'assets/carros/jmc/jmc_jmev_ev3.png'},
    ],
    'OPEL': [
      {'modelo': 'ROCKS-E', 'img': 'assets/carros/opel/opel_rocks_e.png'},
    ],
  };"""

if "'CHANGAN': [" not in content:
    content = content.replace("  };\n\n  final Map<String, String> _carLogos = {", new_brands_block + "\n\n  final Map<String, String> _carLogos = {")

# Logos in _carLogos
new_logos_block = """    'CHANGAN': 'assets/logos/changan.png',
    'CHERY': 'assets/logos/chery.png',
    'DEEPAL': 'assets/logos/deepal.png',
    'HAVAL': 'assets/logos/haval.png',
    'HONDA': 'assets/logos/honda_logo.png',
    'JMC': 'assets/logos/jmc.png',
    'OPEL': 'assets/logos/opel.png',
  };"""

if "'DEEPAL':" not in content:
    content = content.replace("    'BYD': 'assets/logos/byd_logo.png',\n  };", "    'BYD': 'assets/logos/byd_logo.png',\n" + new_logos_block)

# Colors in _brandColors
new_colors_block = """    'CHANGAN': const Color(0xFF003882),
    'CHERY': const Color(0xFFB01116),
    'DEEPAL': const Color(0xFF007A87),
    'HAVAL': const Color(0xFFD6001C),
    'JMC': const Color(0xFFD32F2F),
    'OPEL': const Color(0xFFFFD500),
  };"""

if "'DEEPAL':" not in content: # in brand colors
    content = content.replace("    'HONDA': const Color(0xFFCC0000),\n  };", "    'HONDA': const Color(0xFFCC0000),\n" + new_colors_block)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("vehicle_catalog_service.dart actualizado con éxito!")
