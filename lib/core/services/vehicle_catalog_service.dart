import 'package:flutter/material.dart';

class VehicleCatalogService {
  static final VehicleCatalogService _instance = VehicleCatalogService._internal();
  factory VehicleCatalogService() => _instance;
  VehicleCatalogService._internal();

  // --- CAR CATALOG ---
  final Map<String, List<Map<String, String>>> _carCatalog = {
    'TOYOTA': [
      {'modelo': 'Corolla', 'img': 'assets/carros/toyota/corolla.png'},
      {'modelo': 'Hilux', 'img': 'assets/carros/toyota/hilux.png'},
      {'modelo': 'YARIS', 'img': 'assets/carros/toyota/yaris.png'},
      {'modelo': 'YARIS CROSS', 'img': 'assets/carros/toyota/yaris_cross.png'},
      {'modelo': 'TUNDRA', 'img': 'assets/carros/toyota/tundra.png'},
      {'modelo': 'LAND CRUISER 300', 'img': 'assets/carros/toyota/landcruiser300.png'},
      {'modelo': 'PRADO', 'img': 'assets/carros/toyota/prado.png'},
      {'modelo': 'HILUX CARGA', 'img': 'assets/carros/toyota/hiluxcarga.png'},
      {'modelo': 'FORTUNER', 'img': 'assets/carros/toyota/fortuner.png'},
      {'modelo': 'COROLLA CROSS', 'img': 'assets/carros/toyota/corolla_cross.png'},
      {'modelo': 'COROLLA CROSS GR-S', 'img': 'assets/carros/toyota/corolla_cross_gr-s.png'},
    ],
    'MAZDA': [
      {'modelo': 'CX-30', 'img': 'assets/carros/mazda/cx30.png'},
      {'modelo': 'CX-5', 'img': 'assets/carros/mazda/cx5.png'},
      {'modelo': 'CX-50', 'img': 'assets/carros/mazda/cx50.png'},
      {'modelo': 'MAZDA 2 HATCHBACK', 'img': 'assets/carros/mazda/mazda2.png'},
      {'modelo': 'MAZDA 2 SEDAN', 'img': 'assets/carros/mazda/mazda2sedan.png'},
      {'modelo': 'MAZDA 3 SEDAN', 'img': 'assets/carros/mazda/mazda3.png'},
    
      {'modelo': 'CX-60', 'img': 'assets/carros/mazda/mazda_cx_60.png'},
      {'modelo': 'CX-90', 'img': 'assets/carros/mazda/mazda_cx_90.png'},
    ],
    'CHEVROLET': [
      {'modelo': 'ONIX TURBO RS', 'img': 'assets/carros/chevrolet/jelly-onix-turbo-rs.png'},
      {'modelo': 'ONIX PRIME HB', 'img': 'assets/carros/chevrolet/2022-tambien-onix-turbo-hb.png'},
      {'modelo': 'ONIX TURBO SEDAN', 'img': 'assets/carros/chevrolet/2024-versiones-onix-turbo-ltz-at.png'},
      {'modelo': 'TRACKER RS', 'img': 'assets/carros/chevrolet/tracker-RS.png'},
      {'modelo': 'CAPTIVA TURBO', 'img': 'assets/carros/chevrolet/captiva.png'},
      {'modelo': 'SAIL', 'img': 'assets/carros/chevrolet/sail.png'},
      {'modelo': 'SPARK GT', 'img': 'assets/carros/chevrolet/spark_gt.png'},
      {'modelo': 'BLAZER EV RS', 'img': 'assets/carros/chevrolet/BLAZEREV.png'},
      {'modelo': 'EQUINOX RS', 'img': 'assets/carros/chevrolet/equinox-rs-blazer-rs.png'},
      {'modelo': 'TRAVERSE RS', 'img': 'assets/carros/chevrolet/traverse.png'},
      {'modelo': 'BLAZER RS', 'img': 'assets/carros/chevrolet/blazers.png'},
      {'modelo': 'MONTANA', 'img': 'assets/carros/chevrolet/Montana.png'},
      {'modelo': 'COLORADO RS', 'img': 'assets/carros/chevrolet/colorado.png'},
      {'modelo': 'SILVERADO', 'img': 'assets/carros/chevrolet/silverado.png'},
    ],
    'RENAULT': [
      {'modelo': 'DUSTER', 'img': 'assets/carros/renault/duster.png'},
      {'modelo': 'DUSTER 1.3 TURBO', 'img': 'assets/carros/renault/duster_turbo.png'},
      {'modelo': 'LOGAN', 'img': 'assets/carros/renault/logan.png'},
      {'modelo': 'SANDERO / STEPWAY', 'img': 'assets/carros/renault/sandero.png'},
      {'modelo': 'STEPWAY', 'img': 'assets/carros/renault/stepway.png'},
      {'modelo': 'KWID', 'img': 'assets/carros/renault/kwid.png'},
      {'modelo': 'KOLEOS', 'img': 'assets/carros/renault/koleos.png'},
    
      {'modelo': 'CAPTUR', 'img': 'assets/carros/renault/renault_captur.png'},
    ],
    'KIA': [
      {'modelo': 'PICANTO', 'img': 'assets/carros/kia/picanto.png'},
      {'modelo': 'RIO', 'img': 'assets/carros/kia/rio.png'},
      {'modelo': 'SELTOS', 'img': 'assets/carros/kia/seltos.png'},
      {'modelo': 'SPORTAGE', 'img': 'assets/carros/kia/sportage.png'},
      {'modelo': 'SONET', 'img': 'assets/carros/kia/sonet.png'},
    
      {'modelo': 'CARENS', 'img': 'assets/carros/kia/kia_carens.png'},
      {'modelo': 'K3', 'img': 'assets/carros/kia/kia_k3.png'},
      {'modelo': 'K3 CROSS', 'img': 'assets/carros/kia/kia_k3_cross.png'},
      {'modelo': 'NIRO', 'img': 'assets/carros/kia/kia_niro.png'},
      {'modelo': 'TASMAN', 'img': 'assets/carros/kia/kia_tasman.png'},
    ],
    'NISSAN': [
      {'modelo': 'VERSA', 'img': 'assets/carros/nissan/versa.png'},
      {'modelo': 'KICKS', 'img': 'assets/carros/nissan/kicks.png'},
      {'modelo': 'FRONTIER', 'img': 'assets/carros/nissan/frontier.png'},
      {'modelo': 'SENTRA', 'img': 'assets/carros/nissan/sentra.png'},
    
      {'modelo': 'MARCH', 'img': 'assets/carros/nissan/nissan_march.png'},
      {'modelo': 'QASHQAI', 'img': 'assets/carros/nissan/nissan_qashqai.png'},
      {'modelo': 'X-TRAIL', 'img': 'assets/carros/nissan/nissan_x_trail.png'},
    ],
    'SUZUKI': [
      {'modelo': 'SWIFT', 'img': 'assets/carros/suzuki/swift.png'},
      {'modelo': 'VITARA', 'img': 'assets/carros/suzuki/vitara.png'},
      {'modelo': 'JIMNY', 'img': 'assets/carros/suzuki/jimny.png'},
    
      {'modelo': 'GRAND VITARA', 'img': 'assets/carros/suzuki/suzuki_grand_vitara.png'},
    ],
    'VOLKSWAGEN': [
      {'modelo': 'GOL', 'img': 'assets/carros/volkswagen/gol.png'},
      {'modelo': 'T-CROSS', 'img': 'assets/carros/volkswagen/tcross.png'},
      {'modelo': 'AMAROK', 'img': 'assets/carros/volkswagen/amarok.png'},
    
      {'modelo': 'JETTA', 'img': 'assets/carros/volkswagen/volkswagen_jetta.png'},
      {'modelo': 'VIRTUS', 'img': 'assets/carros/volkswagen/volkswagen_virtus.png'},
    ],
    'FORD': [
      {'modelo': 'RANGER', 'img': 'assets/carros/ford/ranger.png'},
      {'modelo': 'ESCAPE', 'img': 'assets/carros/ford/escape.png'},
      {'modelo': 'EXPLORER', 'img': 'assets/carros/ford/explorer.png'},
    
      {'modelo': 'BRONCO', 'img': 'assets/carros/ford/ford_bronco.png'},
      {'modelo': 'BRONCO SPORT', 'img': 'assets/carros/ford/ford_bronco_sport.png'},
      {'modelo': 'ECOSPORT', 'img': 'assets/carros/ford/ford_ecosport.png'},
      {'modelo': 'EDGE', 'img': 'assets/carros/ford/ford_edge.png'},
      {'modelo': 'F-150', 'img': 'assets/carros/ford/ford_f_150.png'},
      {'modelo': 'MAVERICK', 'img': 'assets/carros/ford/ford_maverick.png'},
    ],
    'HYUNDAI': [
      {'modelo': 'HB20', 'img': 'assets/carros/hyundai/hb20.png'},
      {'modelo': 'TUCSON', 'img': 'assets/carros/hyundai/tucson.png'},
    
      {'modelo': 'CRETA', 'img': 'assets/carros/hyundai/hyundai_creta.png'},
    ],
    'BYD': [
      {'modelo': 'DOLPHIN MINI', 'img': 'assets/carros/byd/dolphin_mini.png'},
      {'modelo': 'SONG PLUS', 'img': 'assets/carros/byd/song_plus.png'},
    ],

    'AUDI': [
      {'modelo': 'Q3', 'img': 'assets/carros/audi/audi_q3.png'},
      {'modelo': 'S3', 'img': 'assets/carros/audi/audi_s3.png'},
    ],
    'CITROËN': [
      {'modelo': 'C3', 'img': 'assets/carros/citroen/citroen_c3.png'},
      {'modelo': 'C5 AIRCROSS', 'img': 'assets/carros/citroen/citroen_c5_aircross.png'},
    ],
    'CUPRA': [
      {'modelo': 'FORMENTOR', 'img': 'assets/carros/cupra/cupra_formentor.png'},
    ],
    'JEEP': [
      {'modelo': 'WRANGLER UNLIMITED 4X4', 'img': 'assets/carros/jeep/jeep_wrangler_unlimited_4x4.png'},
    ],
    'JETOUR': [
      {'modelo': 'X70', 'img': 'assets/carros/jetour/jetour_x70.png'},
    ],
    'MERCEDES-BENZ': [
      {'modelo': 'CLASE C 200', 'img': 'assets/carros/mercedes_benz/mercedes_benz_clase_c_200.png'},
      {'modelo': 'CLA 250', 'img': 'assets/carros/mercedes_benz/mercedes_benz_cla_250.png'},
      {'modelo': 'CLA 35 AMG', 'img': 'assets/carros/mercedes_benz/mercedes_benz_cla_35_amg.png'},
      {'modelo': 'CLE 300 COUPÉ', 'img': 'assets/carros/mercedes_benz/mercedes_benz_cle_300_coup.png'},
      {'modelo': 'EQA 250+ ELÉCTRICO', 'img': 'assets/carros/mercedes_benz/mercedes_benz_eqa_250_el_ctrico.png'},
      {'modelo': 'GLA 250', 'img': 'assets/carros/mercedes_benz/mercedes_benz_gla_250.png'},
      {'modelo': 'GLC 300 4MATIC', 'img': 'assets/carros/mercedes_benz/mercedes_benz_glc_300_4matic.png'},
      {'modelo': 'GLC 350E HÍBRIDO', 'img': 'assets/carros/mercedes_benz/mercedes_benz_glc_350e_h_brido.png'},
      {'modelo': 'GLE 450 4MATIC', 'img': 'assets/carros/mercedes_benz/mercedes_benz_gle_450_4matic.png'},
    ],
    'MINI': [
      {'modelo': 'COUNTRYMAN', 'img': 'assets/carros/mini/mini_countryman.png'},
    ],
    'MITSUBISHI': [
      {'modelo': 'ECLIPSE CROSS', 'img': 'assets/carros/mitsubishi/mitsubishi_eclipse_cross.png'},
    ],
    'PEUGEOT': [
      {'modelo': '208', 'img': 'assets/carros/peugeot/peugeot_208.png'},
      {'modelo': '2008', 'img': 'assets/carros/peugeot/peugeot_2008.png'},
    ],
    'SEAT': [
      {'modelo': 'ATECA', 'img': 'assets/carros/seat/seat_ateca.png'},
      {'modelo': 'TARRACO', 'img': 'assets/carros/seat/seat_tarraco.png'},
    ],
    'SUBARU': [
      {'modelo': 'CROSSTREK', 'img': 'assets/carros/subaru/subaru_crosstrek.png'},
      {'modelo': 'OUTBACK', 'img': 'assets/carros/subaru/subaru_outback.png'},
    ],
    'TESLA': [
      {'modelo': 'MODEL 3', 'img': 'assets/carros/tesla/tesla_model_3.png'},
    ],
    'VOLVO': [
      {'modelo': 'EC40 RECHARGE ELÉCTRICO', 'img': 'assets/carros/volvo/volvo_ec40_recharge_el_ctrico.png'},
      {'modelo': 'XC40 RECHARGE', 'img': 'assets/carros/volvo/volvo_xc40_recharge.png'},
      {'modelo': 'XC60 RECHARGE', 'img': 'assets/carros/volvo/volvo_xc60_recharge.png'},
    ],
  };

  final Map<String, String> _carLogos = {
    'VOLVO': 'assets/logos/volvo.png',
    'TESLA': 'assets/logos/tesla.png',
    'SUBARU': 'assets/logos/subaru.png',
    'SEAT': 'assets/logos/seat.png',
    'PEUGEOT': 'assets/logos/peugeot_logo.png',
    'MITSUBISHI': 'assets/logos/mitsubishi_logo.png',
    'MINI': 'assets/logos/mini.png',
    'MERCEDES-BENZ': 'assets/logos/mercedes_logo.png',
    'JETOUR': 'assets/logos/jetour.png',
    'JEEP': 'assets/logos/jeep_logo.png',
    'CUPRA': 'assets/logos/cupra.png',
    'CITROËN': 'assets/logos/citroen.png',
    'BMW': 'assets/logos/bmw_logo.png',
    'AUDI': 'assets/logos/audi_logo.png',
    'TOYOTA': 'assets/logos/toyota_logo.png',
    'MAZDA': 'assets/logos/mazda_logo.png',
    'CHEVROLET': 'assets/logos/chevrolet_logo.png',
    'RENAULT': 'assets/logos/renault_logo.png',
    'KIA': 'assets/logos/kia_logo.png',
    'NISSAN': 'assets/logos/nissan_logo.png',
    'SUZUKI': 'assets/logos/suzuki_logo.png',
    'VOLKSWAGEN': 'assets/logos/volkswagen_logo.png',
    'FORD': 'assets/logos/ford_logo.png',
    'HYUNDAI': 'assets/logos/hyundai_logo.png',
    'BYD': 'assets/logos/byd_logo.png',
  };

  // --- MOTO CATALOG ---
  final Map<String, List<Map<String, String>>> _motoCatalog = {
    'YAMAHA': [
      {'modelo': 'BWS FI 125', 'img': 'assets/motos/yamaha/bws125.png'},
      {'modelo': 'N-MAX', 'img': 'assets/motos/yamaha/nmax.png'},
      {'modelo': 'AEROX 155', 'img': 'assets/motos/yamaha/aerox155.png'},
      {'modelo': 'MT 15', 'img': 'assets/motos/yamaha/mt15.png'},
      {'modelo': 'MT 09', 'img': 'assets/motos/yamaha/mt09.png'},
      {'modelo': 'FZ 25', 'img': 'assets/motos/yamaha/fz25.png'},
      {'modelo': 'FZ 2.0', 'img': 'assets/motos/yamaha/fz2.0.png'},
      {'modelo': 'CRYPTON FI', 'img': 'assets/motos/yamaha/cripton.png'},
      {'modelo': 'XTZ 150', 'img': 'assets/motos/yamaha/XTZ150.png'},
      {'modelo': 'XTZ 250 LANDER', 'img': 'assets/motos/yamaha/xtz250.png'},
      {'modelo': 'R15', 'img': 'assets/motos/yamaha/r15.png'},
    ],
    'SUZUKI': [
      {'modelo': 'AX4 115', 'img': 'assets/motos/suzuki/ax4.png'},
      {'modelo': 'Gixxer 150 FI', 'img': 'assets/motos/suzuki/gixxer150.png'},
      {'modelo': 'Gixxer SF 150 FI', 'img': 'assets/motos/suzuki/gixxersf150.png'},
      {'modelo': 'GIXXER 250', 'img': 'assets/motos/suzuki/gixxer250.png'},
      {'modelo': 'GIXXER SF 250', 'img': 'assets/motos/suzuki/gixxersf250.png'},
      {'modelo': 'DR 150', 'img': 'assets/motos/suzuki/DR.png'},
      {'modelo': 'ADDRESS 125', 'img': 'assets/motos/suzuki/address125.png'},
      {'modelo': 'BURGMAN 125', 'img': 'assets/motos/suzuki/burgman.png'},
      {'modelo': 'FLEX 125', 'img': 'assets/motos/suzuki/FLEX.png'},
      {'modelo': 'GSX-R 150', 'img': 'assets/motos/suzuki/gsxr150.png'},
      {'modelo': 'VIVA R STYLE 115', 'img': 'assets/motos/suzuki/vivarstyle115.png'},
      {'modelo': 'GSX-S 150', 'img': 'assets/motos/suzuki/GSX-S150.png'},
      {'modelo': 'GSX-S 1000', 'img': 'assets/motos/suzuki/GSXS1000.png'},
      {'modelo': 'V-STROM 160', 'img': 'assets/motos/suzuki/VSTROM-160.png'},
      {'modelo': 'V-STROM 250 SX', 'img': 'assets/motos/suzuki/VSTROM-250-SX.png'},
      {'modelo': 'GN 125', 'img': 'assets/motos/suzuki/GN125.png'},
      {'modelo': 'HAYABUSA', 'img': 'assets/motos/suzuki/hayabusa.png'},
    ],
    'BMW': [
      {'modelo': 'G 310 R', 'img': 'assets/motos/bmw/g310r.png'},
      {'modelo': 'G 310 GS', 'img': 'assets/motos/bmw/g310gs.png'},
      {'modelo': 'F 900 R', 'img': 'assets/motos/bmw/f900r.png'},
    
      {'modelo': '218I GRAN COUPÉ', 'img': 'assets/carros/bmw/bmw_218i_gran_coup.png'},
      {'modelo': '530I SEDAN', 'img': 'assets/carros/bmw/bmw_530i_sedan.png'},
      {'modelo': 'X5', 'img': 'assets/carros/bmw/bmw_x5.png'},
    ],
    'KAWASAKI': [
      {'modelo': 'VERSYS 650', 'img': 'assets/motos/kawasaki/versys650.png'},
      {'modelo': 'Ninja 650', 'img': 'assets/motos/kawasaki/ninja650.png'},
      {'modelo': 'Ninja 400', 'img': 'assets/motos/kawasaki/ninja400.png'},
      {'modelo': 'Z 400', 'img': 'assets/motos/kawasaki/z400.png'},
      {'modelo': 'Z 500', 'img': 'assets/motos/kawasaki/z500.png'},
      {'modelo': 'Z 900', 'img': 'assets/motos/kawasaki/z900.png'},
    ],
    'BAJAJ': [
      {'modelo': 'BOXER CT 100 KS', 'img': 'assets/motos/bajaj/boxer-ct100-ks.png'},
      {'modelo': 'BOXER CT 100 ES', 'img': 'assets/motos/bajaj/boxer-ct100.png'},
      {'modelo': 'BOXER CT 125 SPORT', 'img': 'assets/motos/bajaj/boxer-ct-125-sport.png'},
      {'modelo': 'BOXER 150 X', 'img': 'assets/motos/bajaj/boxer-150x.png'},
      {'modelo': 'BOXER S', 'img': 'assets/motos/bajaj/boxer-s.png'},
      {'modelo': 'DISCOVER 125', 'img': 'assets/motos/bajaj/discover-125.png'},
      {'modelo': 'DOMINAR 250', 'img': 'assets/motos/bajaj/Dominar-250.png'},
      {'modelo': 'DOMINAR 400 TOURING', 'img': 'assets/motos/bajaj/Dominar-400-touring.png'},
      {'modelo': 'DOMINAR 400 VOLCANO', 'img': 'assets/motos/bajaj/dominar400-volcano.png'},
      {'modelo': 'PULSAR N125', 'img': 'assets/motos/bajaj/pulsar-n125.png'},
      {'modelo': 'PULSAR N160 PRO', 'img': 'assets/motos/bajaj/pulsar-n160-pro.png'},
      {'modelo': 'PULSAR N160', 'img': 'assets/motos/bajaj/pulsar-n160.png'},
      {'modelo': 'PULSAR N250', 'img': 'assets/motos/bajaj/Pulsar-N250.png'},
      {'modelo': 'PULSAR NS 125', 'img': 'assets/motos/bajaj/pulsar-ns-125.png'},
      {'modelo': 'PULSAR NS 160 FI', 'img': 'assets/motos/bajaj/pulsar-ns160-fi.png'},
      {'modelo': 'PULSAR NS 160 FI ABS', 'img': 'assets/motos/bajaj/pulsar-ns-160-fi-abs.png'},
      {'modelo': 'PULSAR NS 200 UG', 'img': 'assets/motos/bajaj/pulsar-ns-200-ug.png'},
      {'modelo': 'PULSAR NS 200 FI ABS', 'img': 'assets/motos/bajaj/pulsar-ns200-fi-abs.png'},
      {'modelo': 'PULSAR NS 400Z', 'img': 'assets/motos/bajaj/pulsar-ns400z.png'},
      {'modelo': 'PULSARMANIA', 'img': 'assets/motos/bajaj/pulsarmania.png'},
      {'modelo': 'PULSAR P150', 'img': 'assets/motos/bajaj/Pulsar-p150.png'},
      {'modelo': 'PULSAR RS 200', 'img': 'assets/motos/bajaj/pulsar-rs200.png'},
    ],
    'HERO': [
      {'modelo': 'HUNK 125 R', 'img': 'assets/motos/hero/Hunk125r.png'},
      {'modelo': 'HUNK 150 XT', 'img': 'assets/motos/hero/Hunk150xt.png'},
      {'modelo': 'HUNK 160 R', 'img': 'assets/motos/hero/hunk160r.png'},
      {'modelo': 'HUNK 160 R 4V', 'img': 'assets/motos/hero/Hunk160R4v.png'},
      {'modelo': 'ECO DELUXE', 'img': 'assets/motos/hero/Eco_Deluxe.png'},
      {'modelo': 'ECO T', 'img': 'assets/motos/hero/ECO-T.png'},
      {'modelo': 'ECO 100', 'img': 'assets/motos/hero/Eco100.png'},
      {'modelo': 'ECO DELUXE CLÁSICA', 'img': 'assets/motos/hero/EcoDeluxeClasica.png'},
      {'modelo': 'IGNITOR XTECH', 'img': 'assets/motos/hero/IgnitorXtech.png'},
      {'modelo': 'IGNITOR', 'img': 'assets/motos/hero/Ignitor.png'},
      {'modelo': 'SPLENDOR XPRO', 'img': 'assets/motos/hero/Splendor-Xpro.png'},
      {'modelo': 'DASH 125', 'img': 'assets/motos/hero/Dash125.png'},
      {'modelo': 'XOOM 110', 'img': 'assets/motos/hero/Xoom110.png'},
      {'modelo': 'X PULSE 200 4V', 'img': 'assets/motos/hero/Xpulse2004v.png'},
      {'modelo': 'X PULSE PRO 200 4V', 'img': 'assets/motos/hero/XpulsePro2004v.png'},
      {'modelo': 'X PULSE RALLY', 'img': 'assets/motos/hero/XpulseRally.png'},
    ],
    'AKT': [
      {'modelo': 'NKD 125', 'img': 'assets/motos/akt/NKD.png'},
      {'modelo': 'CR4 150', 'img': 'assets/motos/akt/CR4_150.png'},
      {'modelo': 'CR4 200', 'img': 'assets/motos/akt/CR4_200.png'},
      {'modelo': 'TT DUAL SPORT 200', 'img': 'assets/motos/akt/tt200.png'},
      {'modelo': 'TTR 125', 'img': 'assets/motos/akt/ttr125.png'},
      {'modelo': 'SPECIAL 100', 'img': 'assets/motos/akt/special100.png'},
      {'modelo': '250 R', 'img': 'assets/motos/akt/250R.png'},
      {'modelo': 'DINAMIC PRO', 'img': 'assets/motos/akt/dinamicpro.png'},
      {'modelo': 'MAWI 125', 'img': 'assets/motos/akt/mawi.png'},
      {'modelo': 'AKT 190', 'img': 'assets/motos/akt/AKT19O.png'},
    ],
    'KTM': [
      {'modelo': 'DUKE 200', 'img': 'assets/motos/ktm/DUKE-200.png'},
      {'modelo': 'DUKE 250', 'img': 'assets/motos/ktm/KTM-250-DUKE.png'},
      {'modelo': 'DUKE 390', 'img': 'assets/motos/ktm/KTM-390-DUKE.png'},
      {'modelo': 'DUKE 990', 'img': 'assets/motos/ktm/KTM-990-DUKE.png'},
      {'modelo': '1390 SUPER DUKE R 2025', 'img': 'assets/motos/ktm/KTM1390superduke2025.png'},
      {'modelo': 'ADVENTURE 250', 'img': 'assets/motos/ktm/KTM-250-Adventure.png'},
      {'modelo': 'ADVENTURE 390', 'img': 'assets/motos/ktm/KTM-390-adv.png'},
      {'modelo': 'ADVENTURE 390 SW', 'img': 'assets/motos/ktm/KTM-390-adventure.png'},
    ],
    'VICTORI': [
      {'modelo': 'VENOM 150', 'img': 'assets/motos/victori/victori_venom_150.png'},
      {'modelo': 'ONE MP', 'img': 'assets/motos/victori/victori_one_mp.png'},
    ],
    'TVS': [
      {'modelo': 'NTORQ 125', 'img': 'assets/motos/tvs/ntorq125.png'},
      {'modelo': 'RAIDER 125', 'img': 'assets/motos/tvs/raider125.png'},
      {'modelo': 'APACHE RTR 160 4V', 'img': 'assets/motos/tvs/apache160.png'},
      {'modelo': 'APACHE RTR 200 4V', 'img': 'assets/motos/tvs/apache200.png'},
      {'modelo': 'APACHE RTR 310', 'img': 'assets/motos/tvs/apache310.png'},
      {'modelo': 'RONIN 225', 'img': 'assets/motos/tvs/ronin225.png'},
    ],
    'HONDA': [
      {'modelo': 'XR 150L', 'img': 'assets/motos/honda/xr150l.png'},
      {'modelo': 'XR 190L', 'img': 'assets/motos/honda/xr190l.png'},
      {'modelo': 'CB 190R', 'img': 'assets/motos/honda/cb190r.png'},
      {'modelo': 'NAVI 110', 'img': 'assets/motos/honda/navi110.png'},
      {'modelo': 'CB 125F', 'img': 'assets/motos/honda/cb125f.png'},
      {'modelo': 'CB 160F', 'img': 'assets/motos/honda/cb160f.png'},
    ],
  };

  final Map<String, String> _motoLogos = {
    'YAMAHA': 'assets/logos/yamaha_logo.png',
    'SUZUKI': 'assets/logos/suzuki_logo.png',
    'BMW': 'assets/logos/bmw_logo.png',
    'KAWASAKI': 'assets/logos/kawa_logo.png',
    'KTM': 'assets/logos/ktm_logo.png',
    'BAJAJ': 'assets/logos/bajaj_logo.png',
    'HERO': 'assets/logos/hero_logo.png',
    'AKT': 'assets/logos/akt_logo.png',
    'VICTORI': 'assets/logos/victori_logo.png',
    'TVS': 'assets/logos/tvs_logo.png',
    'HONDA': 'assets/logos/honda_logo.png',
  };

  // --- BRAND COLORS (Shared) ---
  final Map<String, Color> _brandColors = {
    'VOLVO': const Color(0xFF003057),
    'TESLA': const Color(0xFFE82127),
    'SUBARU': const Color(0xFF013C74),
    'SEAT': const Color(0xFFD50000),
    'PEUGEOT': const Color(0xFF002663),
    'MITSUBISHI': const Color(0xFFE60012),
    'MINI': const Color(0xFF1B1B1B),
    'MERCEDES-BENZ': const Color(0xFF00ADEF),
    'JETOUR': const Color(0xFF1E395B),
    'JEEP': const Color(0xFFFFC80A),
    'CUPRA': const Color(0xFFBE5E2A),
    'CITROËN': const Color(0xFF6E1D24),
    'AUDI': const Color(0xFFBB0A30),
    'TOYOTA': const Color(0xFFEB0A1E),
    'MAZDA': const Color(0xFF1B1B1B),
    'CHEVROLET': const Color(0xFFFFC107),
    'RENAULT': const Color(0xFFFFCC00),
    'KIA': const Color(0xFF05141F),
    'NISSAN': const Color(0xFFC3002F),
    'VOLKSWAGEN': const Color(0xFF001E50),
    'FORD': const Color(0xFF003478),
    'HYUNDAI': const Color(0xFF002C6C),
    'BYD': const Color(0xFFE60012),
    'YAMAHA': const Color(0xFF0055CC),
    'SUZUKI': const Color(0xFFE30613),
    'BMW': const Color(0xFF2A2A2A),
    'KAWASAKI': const Color(0xFF00A651),
    'KTM': const Color(0xFFFF7B00),
    'BAJAJ': const Color(0xFF006EFF),
    'HERO': Colors.black,
    'AKT': const Color.fromARGB(255, 21, 54, 172),
    'VICTORI': const Color.fromARGB(255, 203, 167, 61),
    'TVS': const Color(0xFF002B49),
    'HONDA': const Color(0xFFCC0000),
  };

  // Getters
  Map<String, List<Map<String, String>>> getCarCatalog() => _carCatalog;
  Map<String, String> getCarLogos() => _carLogos;

  Map<String, List<Map<String, String>>> getMotoCatalog() => _motoCatalog;
  Map<String, String> getMotoLogos() => _motoLogos;

  Map<String, Color> getBrandColors() => _brandColors;

  /// Resuelve de forma inteligente la ruta de imagen del vehículo a partir
  /// de su marca y modelo (ej. 'BAJAJ' y 'BAJAJ PULSAR NS 200' o 'PULSAR NS 200').
  String? resolveVehicleImage(String marca, String modelo, {bool isCar = false}) {
    final mUpper = marca.toUpperCase().trim();
    final modUpper = modelo.toUpperCase().trim();
    if (mUpper.isEmpty && modUpper.isEmpty) return null;

    final primary = isCar ? _carCatalog : _motoCatalog;
    final secondary = isCar ? _motoCatalog : _carCatalog;

    String cleanModel(String text) {
      return text
          .replaceAll(mUpper, '')
          .replaceAll('MOTO', '')
          .replaceAll('CARRO', '')
          .replaceAll(RegExp(r'[^A-Z0-9 ]'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }

    final queryClean = cleanModel(modUpper);

    // 1. Búsqueda directa por marca
    if (primary.containsKey(mUpper)) {
      for (final item in primary[mUpper]!) {
        final candidate = (item['modelo'] ?? '').toUpperCase().trim();
        final candidateClean = cleanModel(candidate);
        if (candidate == modUpper ||
            (queryClean.isNotEmpty && (candidateClean.contains(queryClean) || queryClean.contains(candidateClean)))) {
          return item['img'];
        }
      }
    }

    // 2. Búsqueda exhaustiva en catálogo primario
    for (final entry in primary.entries) {
      for (final item in entry.value) {
        final candidate = (item['modelo'] ?? '').toUpperCase().trim();
        final candidateClean = cleanModel(candidate);
        if (queryClean.isNotEmpty &&
            (candidateClean.contains(queryClean) || queryClean.contains(candidateClean))) {
          return item['img'];
        }
      }
    }

    // 3. Búsqueda en catálogo secundario
    for (final entry in secondary.entries) {
      for (final item in entry.value) {
        final candidate = (item['modelo'] ?? '').toUpperCase().trim();
        final candidateClean = cleanModel(candidate);
        if (queryClean.isNotEmpty &&
            (candidateClean.contains(queryClean) || queryClean.contains(candidateClean))) {
          return item['img'];
        }
      }
    }

    return null;
  }
}
