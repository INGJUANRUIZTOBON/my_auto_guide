-- =============================================================================
-- MIGRACIÓN AUTOLAND COLOMBIA: 24 MARCAS Y 52 MODELOS CON FOTOS TRANSPARENTES
-- =============================================================================

-- 1. REGISTRO Y ACTUALIZACIÓN DE MARCAS AUTOMOTRICES
INSERT INTO catalogo_marcas (id, nombre, tipo, logo_url, color_hex, pais_origen, popularidad, activo)
VALUES
  ('audi', 'Audi', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/audi_logo.png', '#BB0A30', 'Alemania', 84, true),
  ('bmw', 'BMW', 'ambos', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/bmw_logo.png', '#0066B1', 'Alemania', 88, true),
  ('citroen', 'Citroën', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/citroen.png', '#6E1D24', 'Francia', 75, true),
  ('cupra', 'Cupra', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/cupra.png', '#BE5E2A', 'España', 79, true),
  ('ford', 'Ford', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/ford_logo.png', '#002C6C', 'Estados Unidos', 89, true),
  ('hyundai', 'Hyundai', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/hyundai_logo.png', '#002C5F', 'Corea del Sur', 87, true),
  ('jeep', 'Jeep', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/jeep_logo.png', '#FFC80A', 'Estados Unidos', 81, true),
  ('jetour', 'Jetour', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/jetour.png', '#1E395B', 'China', 72, true),
  ('kia', 'Kia', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/kia_logo.png', '#05141F', 'Corea del Sur', 91, true),
  ('mazda', 'Mazda', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/mazda_logo.png', '#1B365D', 'Japón', 93, true),
  ('mercedes_benz', 'Mercedes-Benz', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/mercedes_logo.png', '#00ADEF', 'Alemania', 86, true),
  ('mini', 'Mini', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/mini.png', '#1B1B1B', 'Reino Unido', 75, true),
  ('mitsubishi', 'Mitsubishi', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/mitsubishi_logo.png', '#E60012', 'Japón', 77, true),
  ('nissan', 'Nissan', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/nissan_logo.png', '#C3002F', 'Japón', 90, true),
  ('peugeot', 'Peugeot', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/peugeot_logo.png', '#002663', 'Francia', 78, true),
  ('renault', 'Renault', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/renault_logo.png', '#FFCC00', 'Francia', 95, true),
  ('seat', 'Seat', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/seat.png', '#D50000', 'España', 74, true),
  ('subaru', 'Subaru', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/subaru.png', '#013C74', 'Japón', 79, true),
  ('suzuki', 'Suzuki', 'ambos', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/suzuki_logo.png', '#E30613', 'Japón', 89, true),
  ('tesla', 'Tesla', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/tesla.png', '#E82127', 'Estados Unidos', 82, true),
  ('volkswagen', 'Volkswagen', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/volkswagen_logo.png', '#001E50', 'Alemania', 90, true),
  ('volvo', 'Volvo', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/volvo.png', '#003057', 'Suecia', 83, true)
ON CONFLICT (id) DO UPDATE SET
  nombre = EXCLUDED.nombre,
  logo_url = EXCLUDED.logo_url,
  color_hex = EXCLUDED.color_hex,
  popularidad = GREATEST(catalogo_marcas.popularidad, EXCLUDED.popularidad),
  activo = true;

-- 2. REGISTRO DE MODELOS COLOMBIANOS AUTOLAND
INSERT INTO catalogo_modelos (marca_id, tipo, linea, modelo, anio_inicio, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES
  ('audi', 'carro', 'Q3', 'Audi Q3', 2022, 1400, 'Gasolina', 14.5, 120, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/audi/audi_q3.png', 85, true),
  ('audi', 'carro', 'S3', 'Audi S3', 2023, 2000, 'Gasolina', 14.5, 180, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/audi/audi_s3.png', 85, true),
  ('bmw', 'carro', '218i Gran Coupé', 'BMW 218i Gran Coupé', 2020, 1500, 'Gasolina', 14.5, 120, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/bmw/bmw_218i_gran_coup.png', 85, true),
  ('bmw', 'carro', '530i Sedan', 'BMW 530i Sedan', 2023, 2000, 'Gasolina', 14.5, 180, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/bmw/bmw_530i_sedan.png', 85, true),
  ('bmw', 'carro', 'X5', 'BMW X5', 2023, 3000, 'Gasolina', 14.5, 300, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/bmw/bmw_x5.png', 85, true),
  ('citroen', 'carro', 'C3', 'Citroën C3', 2024, 1600, 'Gasolina', 14.5, 120, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/citroen/citroen_c3.png', 85, true),
  ('citroen', 'carro', 'C5 Aircross', 'Citroën C5 Aircross', 2020, 1600, 'Gasolina', 14.5, 120, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/citroen/citroen_c5_aircross.png', 85, true),
  ('cupra', 'carro', 'Formentor', 'Cupra Formentor', 2024, 2000, 'Gasolina', 14.5, 150, '5W-30 Sintético API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/cupra/cupra_formentor.png', 85, true),
  ('ford', 'carro', 'Bronco', 'Ford Bronco', 2025, 2000, 'Gasolina', 14.5, 150, '5W-30 Sintético API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/ford/ford_bronco.png', 85, true),
  ('ford', 'carro', 'Bronco Sport', 'Ford Bronco Sport', 2021, 2000, 'Gasolina', 14.5, 180, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/ford/ford_bronco_sport.png', 85, true),
  ('ford', 'carro', 'Ecosport', 'Ford Ecosport', 2018, 2000, 'Gasolina', 14.5, 180, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/ford/ford_ecosport.png', 85, true),
  ('ford', 'carro', 'Edge', 'Ford Edge', 2017, 3500, 'Gasolina', 14.5, 300, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/ford/ford_edge.png', 85, true),
  ('ford', 'carro', 'F-150', 'Ford F-150', 2023, 3500, 'Híbrido', 14.5, 300, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/ford/ford_f_150.png', 85, true),
  ('ford', 'carro', 'Maverick', 'Ford Maverick', 2025, 2000, 'Gasolina', 14.5, 150, '5W-30 Sintético API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/ford/ford_maverick.png', 85, true),
  ('hyundai', 'carro', 'Creta', 'Hyundai Creta', 2019, 1600, 'Gasolina', 14.5, 120, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/hyundai/hyundai_creta.png', 85, true),
  ('jeep', 'carro', 'Wrangler Unlimited 4x4', 'Jeep Wrangler Unlimited 4x4', 2019, 3600, 'Gasolina', 14.5, 300, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/jeep/jeep_wrangler_unlimited_4x4.png', 85, true),
  ('jetour', 'carro', 'X70', 'Jetour X70', 2023, 1500, 'Gasolina', 14.5, 120, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/jetour/jetour_x70.png', 85, true),
  ('kia', 'carro', 'Carens', 'Kia Carens', 2015, 2000, 'Gasolina', 14.5, 180, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/kia/kia_carens.png', 85, true),
  ('kia', 'carro', 'K3', 'Kia K3', 2027, 2000, 'Gasolina', 14.5, 150, '5W-30 Sintético API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/kia/kia_k3.png', 85, true),
  ('kia', 'carro', 'K3 Cross', 'Kia K3 Cross', 2026, 2000, 'Gasolina', 14.5, 150, '5W-30 Sintético API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/kia/kia_k3_cross.png', 85, true),
  ('kia', 'carro', 'Niro', 'Kia Niro', 2020, 1600, 'Gasolina', 14.5, 120, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/kia/kia_niro.png', 85, true),
  ('kia', 'carro', 'Tasman', 'Kia Tasman', 2026, 2000, 'Gasolina', 14.5, 150, '5W-30 Sintético API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/kia/kia_tasman.png', 85, true),
  ('mazda', 'carro', 'CX-60', 'Mazda CX-60', 2024, 2000, 'Gasolina', 14.5, 150, '5W-30 Sintético API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/mazda/mazda_cx_60.png', 85, true),
  ('mazda', 'carro', 'CX-90', 'Mazda CX-90', 2025, 2000, 'Gasolina', 14.5, 150, '5W-30 Sintético API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/mazda/mazda_cx_90.png', 85, true),
  ('mercedes_benz', 'carro', 'Clase C 200', 'Mercedes-Benz Clase C 200', 2020, 2000, 'Gasolina', 14.5, 180, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/mercedes_benz/mercedes_benz_clase_c_200.png', 85, true),
  ('mercedes_benz', 'carro', 'CLA 250', 'Mercedes-Benz CLA 250', 2026, 2000, 'Gasolina', 14.5, 180, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/mercedes_benz/mercedes_benz_cla_250.png', 85, true),
  ('mercedes_benz', 'carro', 'CLA 35 AMG', 'Mercedes-Benz CLA 35 AMG', 2026, 2000, 'Gasolina', 14.5, 180, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/mercedes_benz/mercedes_benz_cla_35_amg.png', 85, true),
  ('mercedes_benz', 'carro', 'CLE 300 Coupé', 'Mercedes-Benz CLE 300 Coupé', 2026, 2000, 'Gasolina', 14.5, 150, '5W-30 Sintético API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/mercedes_benz/mercedes_benz_cle_300_coup.png', 85, true),
  ('mercedes_benz', 'carro', 'EQA 250+ Eléctrico', 'Mercedes-Benz EQA 250+ Eléctrico', 2026, 2000, 'Eléctrico', 0.0, 280, 'Líquido Refrigerante Batería EV', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/mercedes_benz/mercedes_benz_eqa_250_el_ctrico.png', 85, true),
  ('mercedes_benz', 'carro', 'GLA 250', 'Mercedes-Benz GLA 250', 2025, 2000, 'Gasolina', 14.5, 180, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/mercedes_benz/mercedes_benz_gla_250.png', 85, true),
  ('mercedes_benz', 'carro', 'GLC 300 4MATIC', 'Mercedes-Benz GLC 300 4MATIC', 2025, 2000, 'Híbrido', 14.5, 180, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/mercedes_benz/mercedes_benz_glc_300_4matic.png', 85, true),
  ('mercedes_benz', 'carro', 'GLC 350e Híbrido', 'Mercedes-Benz GLC 350e Híbrido', 2023, 2000, 'Híbrido', 14.5, 180, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/mercedes_benz/mercedes_benz_glc_350e_h_brido.png', 85, true),
  ('mercedes_benz', 'carro', 'GLE 450 4MATIC', 'Mercedes-Benz GLE 450 4MATIC', 2026, 2000, 'Gasolina', 14.5, 150, '5W-30 Sintético API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/mercedes_benz/mercedes_benz_gle_450_4matic.png', 85, true),
  ('mini', 'carro', 'Countryman', 'Mini Countryman', 2019, 2000, 'Gasolina', 14.5, 180, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/mini/mini_countryman.png', 85, true),
  ('mitsubishi', 'carro', 'Eclipse Cross', 'Mitsubishi Eclipse Cross', 2023, 2000, 'Gasolina', 14.5, 180, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/mitsubishi/mitsubishi_eclipse_cross.png', 85, true),
  ('nissan', 'carro', 'March', 'Nissan March', 2020, 1600, 'Gasolina', 14.5, 120, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/nissan/nissan_march.png', 85, true),
  ('nissan', 'carro', 'Qashqai', 'Nissan Qashqai', 2021, 2000, 'Gasolina', 14.5, 180, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/nissan/nissan_qashqai.png', 85, true),
  ('nissan', 'carro', 'X-Trail', 'Nissan X-Trail', 2017, 2500, 'Gasolina', 14.5, 225, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/nissan/nissan_x_trail.png', 85, true),
  ('peugeot', 'carro', '208', 'Peugeot 208', 2018, 1600, 'Gasolina', 14.5, 120, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/peugeot/peugeot_208.png', 85, true),
  ('peugeot', 'carro', '2008', 'Peugeot 2008', 2008, 1600, 'Gasolina', 14.5, 120, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/peugeot/peugeot_2008.png', 85, true),
  ('renault', 'carro', 'Captur', 'Renault Captur', 2017, 2000, 'Gasolina', 14.5, 180, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/renault/renault_captur.png', 85, true),
  ('seat', 'carro', 'Ateca', 'Seat Ateca', 2019, 2000, 'Gasolina', 14.5, 180, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/seat/seat_ateca.png', 85, true),
  ('seat', 'carro', 'Tarraco', 'Seat Tarraco', 2023, 1400, 'Gasolina', 14.5, 120, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/seat/seat_tarraco.png', 85, true),
  ('subaru', 'carro', 'Crosstrek', 'Subaru Crosstrek', 2024, 2000, 'Gasolina', 14.5, 180, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/subaru/subaru_crosstrek.png', 85, true),
  ('subaru', 'carro', 'Outback', 'Subaru Outback', 2022, 2400, 'Gasolina', 14.5, 225, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/subaru/subaru_outback.png', 85, true),
  ('suzuki', 'carro', 'Grand Vitara', 'Suzuki Grand Vitara', 2015, 2400, 'Gasolina', 14.5, 225, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/suzuki/suzuki_grand_vitara.png', 85, true),
  ('tesla', 'carro', 'Model 3', 'Tesla Model 3', 2026, 2000, 'Eléctrico', 0.0, 280, 'Líquido Refrigerante Batería EV', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/tesla/tesla_model_3.png', 85, true),
  ('volkswagen', 'carro', 'Jetta', 'Volkswagen Jetta', 2023, 1400, 'Gasolina', 14.5, 120, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/volkswagen/volkswagen_jetta.png', 85, true),
  ('volkswagen', 'carro', 'Virtus', 'Volkswagen Virtus', 2022, 1600, 'Gasolina', 14.5, 120, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/volkswagen/volkswagen_virtus.png', 85, true),
  ('volvo', 'carro', 'EC40 Recharge Eléctrico', 'Volvo EC40 Recharge Eléctrico', 2026, 2000, 'Eléctrico', 0.0, 280, 'Líquido Refrigerante Batería EV', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/volvo/volvo_ec40_recharge_el_ctrico.png', 85, true),
  ('volvo', 'carro', 'XC40 Recharge', 'Volvo XC40 Recharge', 2021, 2000, 'Gasolina', 14.5, 180, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/volvo/volvo_xc40_recharge.png', 85, true),
  ('volvo', 'carro', 'XC60 Recharge', 'Volvo XC60 Recharge', 2025, 2000, 'Híbrido', 14.5, 180, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/volvo/volvo_xc60_recharge.png', 85, true)
ON CONFLICT (marca_id, tipo, linea) DO UPDATE SET
  modelo = EXCLUDED.modelo,
  imagen_url = EXCLUDED.imagen_url,
  cilindraje_cc = EXCLUDED.cilindraje_cc,
  tipo_combustible = EXCLUDED.tipo_combustible,
  aceite_recomendado = EXCLUDED.aceite_recomendado,
  activo = true;

-- 3. REGISTRO DE ACTUALIZACIÓN AUTOMÁTICA OTA (v1.2.11+28)
INSERT INTO app_versions (version_code, version_name, zip_url, release_notes, is_mandatory, min_supported_version)
VALUES (
  28,
  '1.2.11',
  'https://github.com/INGJUANRUIZTOBON/my_auto_guide/releases/download/1.1.0/app-release.apk',
  '• Catálogo Autoland Colombia: 24 marcas oficiales y 52 nuevos modelos con imágenes HD transparentes.\n• Nuevas Marcas Integradas: Audi, BMW, Citroën, Cupra, Jeep, Jetour, Mercedes-Benz, Mini, Mitsubishi, Peugeot, Seat, Subaru, Tesla y Volvo.\n• Especificaciones Técnicas y Fluidos: Motorización, CC, potencia HP y aceites recomendados integrados automáticamente.\n• Rendimiento Optimizado: Siluetas transparentes sin fondo que se integran con fluidez al tema oscuro del garaje.',
  true,
  1
)
ON CONFLICT (version_code) DO UPDATE SET
  version_name = EXCLUDED.version_name,
  zip_url = EXCLUDED.zip_url,
  release_notes = EXCLUDED.release_notes,
  is_mandatory = true;
