-- =============================================================================
-- MIGRACIÓN UNIFICADA DE CATÁLOGO NACIONAL (AUTOLAND + AUTONAL COLOMBIA)
-- Versión: 1.2.12 (Build 29)
-- Soluciona ERROR 42P10 mediante deduplicación previa y creación de índice único
-- =============================================================================

-- PASO 1: CORRECCIÓN ESTRUCTURAL DE RESTRICCIÓN ÚNICA (Previene error 42P10)
DELETE FROM public.catalogo_modelos a USING public.catalogo_modelos b
WHERE a.id < b.id
  AND a.marca_id = b.marca_id
  AND a.tipo = b.tipo
  AND a.linea = b.linea;

CREATE UNIQUE INDEX IF NOT EXISTS idx_catalogo_modelos_unique_linea
ON public.catalogo_modelos (marca_id, tipo, linea);

CREATE UNIQUE INDEX IF NOT EXISTS idx_catalogo_marcas_id
ON public.catalogo_marcas (id);

-- PASO 2: REGISTRO Y ACTUALIZACIÓN DE MARCAS AUTOMOTRICES (32 Marcas)
INSERT INTO public.catalogo_marcas (id, nombre, tipo, logo_url, color_hex, pais_origen, popularidad, activo)
VALUES
  ('audi', 'Audi', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/audi_logo.png', '#BB0A30', 'Alemania', 84, true),
  ('bmw', 'BMW', 'ambos', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/bmw_logo.png', '#0066B1', 'Alemania', 88, true),
  ('byd', 'BYD', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/byd_logo.png', '#E60012', 'China', 85, true),
  ('changan', 'Changan', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/changan.png', '#003882', 'China', 76, true),
  ('chery', 'Chery', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/chery.png', '#B01116', 'China', 75, true),
  ('chevrolet', 'Chevrolet', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/chevrolet_logo.png', '#CD9834', 'Estados Unidos', 92, true),
  ('citroen', 'Citroën', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/citroen.png', '#6E1D24', 'Francia', 75, true),
  ('cupra', 'Cupra', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/cupra.png', '#BE5E2A', 'España', 79, true),
  ('deepal', 'Deepal', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/deepal.png', '#007A87', 'China', 74, true),
  ('ford', 'Ford', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/ford_logo.png', '#002C6C', 'Estados Unidos', 89, true),
  ('haval', 'Haval', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/haval.png', '#D6001C', 'China', 73, true),
  ('honda', 'Honda', 'ambos', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/honda_logo.png', '#CC0000', 'Japón', 90, true),
  ('hyundai', 'Hyundai', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/hyundai_logo.png', '#002C5F', 'Corea del Sur', 87, true),
  ('jeep', 'Jeep', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/jeep_logo.png', '#FFC80A', 'Estados Unidos', 81, true),
  ('jetour', 'Jetour', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/jetour.png', '#1E395B', 'China', 72, true),
  ('jmc', 'JMC', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/jmc.png', '#D32F2F', 'China', 70, true),
  ('kia', 'Kia', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/kia_logo.png', '#05141F', 'Corea del Sur', 91, true),
  ('mazda', 'Mazda', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/mazda_logo.png', '#1B365D', 'Japón', 93, true),
  ('mercedes_benz', 'Mercedes-Benz', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/mercedes_logo.png', '#00ADEF', 'Alemania', 86, true),
  ('mini', 'Mini', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/mini.png', '#1B1B1B', 'Reino Unido', 75, true),
  ('mitsubishi', 'Mitsubishi', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/mitsubishi_logo.png', '#E60012', 'Japón', 77, true),
  ('nissan', 'Nissan', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/nissan_logo.png', '#C3002F', 'Japón', 90, true),
  ('opel', 'Opel', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/opel.png', '#FFD500', 'Alemania', 71, true),
  ('peugeot', 'Peugeot', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/peugeot_logo.png', '#002663', 'Francia', 78, true),
  ('renault', 'Renault', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/renault_logo.png', '#FFCC00', 'Francia', 95, true),
  ('seat', 'Seat', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/seat.png', '#D50000', 'España', 74, true),
  ('subaru', 'Subaru', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/subaru.png', '#013C74', 'Japón', 79, true),
  ('suzuki', 'Suzuki', 'ambos', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/suzuki_logo.png', '#E30613', 'Japón', 89, true),
  ('tesla', 'Tesla', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/tesla.png', '#E82127', 'Estados Unidos', 82, true),
  ('toyota', 'Toyota', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/toyota_logo.png', '#EB0A1E', 'Japón', 96, true),
  ('volkswagen', 'Volkswagen', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/volkswagen_logo.png', '#001E50', 'Alemania', 90, true),
  ('volvo', 'Volvo', 'carro', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/volvo.png', '#003057', 'Suecia', 83, true)
ON CONFLICT (id) DO UPDATE SET
  nombre = EXCLUDED.nombre,
  tipo = EXCLUDED.tipo,
  logo_url = EXCLUDED.logo_url,
  color_hex = EXCLUDED.color_hex,
  popularidad = GREATEST(catalogo_marcas.popularidad, EXCLUDED.popularidad),
  activo = true;

-- PASO 3: REGISTRO DE TODOS LOS MODELOS (AUTOLAND + AUTONAL)
INSERT INTO public.catalogo_modelos (marca_id, tipo, linea, modelo, anio_inicio, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES
  ('audi', 'carro', 'Q3', 'Audi Q3', 2022, 1400, 'Gasolina', 14.5, 120, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/audi/audi_q3.png', 85, true),
  ('audi', 'carro', 'S3', 'Audi S3', 2023, 2000, 'Gasolina', 14.5, 180, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/audi/audi_s3.png', 85, true),
  ('bmw', 'carro', '218I', 'BMW 218I', 2020, 1500, 'Gasolina', 14.5, 120, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/bmw/bmw_218i_gran_coup.png', 85, true),
  ('bmw', 'carro', '530I', 'BMW 530I', 2023, 2000, 'Gasolina', 14.5, 180, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/bmw/bmw_530i_sedan.png', 85, true),
  ('bmw', 'carro', 'X5', 'BMW X5', 2023, 3000, 'Gasolina', 14.5, 300, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/bmw/bmw_x5.png', 85, true),
  ('citroen', 'carro', 'C3', 'Citroën C3', 2024, 1600, 'Gasolina', 14.5, 120, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/citroen/citroen_c3.png', 85, true),
  ('citroen', 'carro', 'C5 Aircross', 'Citroën C5 Aircross', 2020, 1600, 'Gasolina', 14.5, 120, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/citroen/citroen_c5_aircross.png', 85, true),
  ('cupra', 'carro', 'Formentor', 'Cupra Formentor', 2024, 2000, 'Gasolina', 14.5, 150, '5W-30 Sintético API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/cupra/cupra_formentor.png', 85, true),
  ('ford', 'carro', 'Bronco', 'Ford Bronco', 2025, 2000, 'Gasolina', 14.5, 150, '5W-30 Sintético API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/ford/ford_bronco.png', 85, true),
  ('ford', 'carro', 'Bronco Sport', 'Ford Bronco Sport', 2021, 2000, 'Gasolina', 14.5, 180, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/ford/ford_bronco_sport.png', 85, true),
  ('ford', 'carro', 'Ecosport', 'Ford Ecosport', 2018, 2000, 'Gasolina', 14.5, 180, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/ford/ford_ecosport.png', 85, true),
  ('ford', 'carro', 'Edge', 'Ford Edge', 2017, 3500, 'Gasolina', 14.5, 300, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/ford/ford_edge.png', 85, true),
  ('ford', 'carro', 'F150', 'Ford F150', 2023, 3500, 'Híbrido', 14.5, 300, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/ford/ford_f_150.png', 85, true),
  ('ford', 'carro', 'Maverick', 'Ford Maverick', 2025, 2000, 'Gasolina', 14.5, 150, '5W-30 Sintético API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/ford/ford_maverick.png', 85, true),
  ('hyundai', 'carro', 'Creta', 'Hyundai Creta', 2019, 1600, 'Gasolina', 14.5, 120, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/hyundai/hyundai_creta.png', 85, true),
  ('jeep', 'carro', 'Wrangler Unlimited', 'Jeep Wrangler Unlimited', 2019, 3600, 'Gasolina', 14.5, 300, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/jeep/jeep_wrangler_unlimited_4x4.png', 85, true),
  ('jetour', 'carro', 'X70', 'Jetour X70', 2023, 1500, 'Gasolina', 14.5, 120, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/jetour/jetour_x70.png', 85, true),
  ('kia', 'carro', 'Carens', 'Kia Carens', 2015, 2000, 'Gasolina', 14.5, 180, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/kia/kia_carens.png', 85, true),
  ('kia', 'carro', 'K3', 'Kia K3', 2027, 2000, 'Gasolina', 14.5, 150, '5W-30 Sintético API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/kia/kia_k3.png', 85, true),
  ('kia', 'carro', 'K3 Cross', 'Kia K3 Cross', 2026, 2000, 'Gasolina', 14.5, 150, '5W-30 Sintético API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/kia/kia_k3_cross.png', 85, true),
  ('kia', 'carro', 'Niro', 'Kia Niro', 2020, 1600, 'Gasolina', 14.5, 120, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/kia/kia_niro.png', 85, true),
  ('kia', 'carro', 'Tasman', 'Kia Tasman', 2026, 2000, 'Gasolina', 14.5, 150, '5W-30 Sintético API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/kia/kia_tasman.png', 85, true),
  ('mazda', 'carro', 'Cx60', 'Mazda Cx60', 2024, 2000, 'Gasolina', 14.5, 150, '5W-30 Sintético API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/mazda/mazda_cx_60.png', 85, true),
  ('mazda', 'carro', 'Cx90', 'Mazda Cx90', 2025, 2000, 'Gasolina', 14.5, 150, '5W-30 Sintético API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/mazda/mazda_cx_90.png', 85, true),
  ('mercedes_benz', 'carro', 'C 200', 'Mercedes-Benz C 200', 2020, 2000, 'Gasolina', 14.5, 180, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/mercedes_benz/mercedes_benz_clase_c_200.png', 85, true),
  ('mercedes_benz', 'carro', 'Cla 250', 'Mercedes-Benz Cla 250', 2026, 2000, 'Gasolina', 14.5, 180, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/mercedes_benz/mercedes_benz_cla_250.png', 85, true),
  ('mercedes_benz', 'carro', 'Cla 35', 'Mercedes-Benz Cla 35', 2026, 2000, 'Gasolina', 14.5, 180, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/mercedes_benz/mercedes_benz_cla_35_amg.png', 85, true),
  ('mercedes_benz', 'carro', 'Cle 300', 'Mercedes-Benz Cle 300', 2026, 2000, 'Gasolina', 14.5, 150, '5W-30 Sintético API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/mercedes_benz/mercedes_benz_cle_300_coup.png', 85, true),
  ('mercedes_benz', 'carro', 'Eqa 250+', 'Mercedes-Benz Eqa 250+', 2026, 2000, 'Eléctrico', 14.5, 280, 'Líquido Refrigerante Batería EV', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/mercedes_benz/mercedes_benz_eqa_250_el_ctrico.png', 85, true),
  ('mercedes_benz', 'carro', 'Gla 250', 'Mercedes-Benz Gla 250', 2025, 2000, 'Gasolina', 14.5, 180, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/mercedes_benz/mercedes_benz_gla_250.png', 85, true),
  ('mercedes_benz', 'carro', 'Glc 300', 'Mercedes-Benz Glc 300', 2025, 2000, 'Híbrido', 14.5, 180, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/mercedes_benz/mercedes_benz_glc_300_4matic.png', 85, true),
  ('mercedes_benz', 'carro', 'Glc 350 E', 'Mercedes-Benz Glc 350 E', 2023, 2000, 'Híbrido', 14.5, 180, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/mercedes_benz/mercedes_benz_glc_350e_h_brido.png', 85, true),
  ('mercedes_benz', 'carro', 'Gle 450', 'Mercedes-Benz Gle 450', 2026, 2000, 'Gasolina', 14.5, 150, '5W-30 Sintético API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/mercedes_benz/mercedes_benz_gle_450_4matic.png', 85, true),
  ('mini', 'carro', 'Countryman', 'Mini Countryman', 2019, 2000, 'Gasolina', 14.5, 180, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/mini/mini_countryman.png', 85, true),
  ('mitsubishi', 'carro', 'Eclipse Cross', 'Mitsubishi Eclipse Cross', 2023, 2000, 'Gasolina', 14.5, 180, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/mitsubishi/mitsubishi_eclipse_cross.png', 85, true),
  ('nissan', 'carro', 'March', 'Nissan March', 2020, 1600, 'Gasolina', 14.5, 120, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/nissan/nissan_march.png', 85, true),
  ('nissan', 'carro', 'Qashqai', 'Nissan Qashqai', 2021, 2000, 'Gasolina', 14.5, 180, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/nissan/nissan_qashqai.png', 85, true),
  ('nissan', 'carro', 'X Trail', 'Nissan X Trail', 2017, 2500, 'Gasolina', 14.5, 225, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/nissan/nissan_x_trail.png', 85, true),
  ('peugeot', 'carro', '208', 'Peugeot 208', 2018, 1600, 'Gasolina', 14.5, 120, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/peugeot/peugeot_208.png', 85, true),
  ('peugeot', 'carro', 'Peugeot', 'Peugeot Peugeot', 2008, 1600, 'Gasolina', 14.5, 120, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/peugeot/peugeot_2008.png', 85, true),
  ('renault', 'carro', 'Captur', 'Renault Captur', 2017, 2000, 'Gasolina', 14.5, 180, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/renault/renault_captur.png', 85, true),
  ('seat', 'carro', 'Ateca', 'Seat Ateca', 2019, 2000, 'Gasolina', 14.5, 180, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/seat/seat_ateca.png', 85, true),
  ('seat', 'carro', 'Tarraco', 'Seat Tarraco', 2023, 1400, 'Gasolina', 14.5, 120, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/seat/seat_tarraco.png', 85, true),
  ('subaru', 'carro', 'Crosstrek', 'Subaru Crosstrek', 2024, 2000, 'Gasolina', 14.5, 180, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/subaru/subaru_crosstrek.png', 85, true),
  ('subaru', 'carro', 'Outback', 'Subaru Outback', 2022, 2400, 'Gasolina', 14.5, 225, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/subaru/subaru_outback.png', 85, true),
  ('suzuki', 'carro', 'Grand Vitara', 'Suzuki Grand Vitara', 2015, 2400, 'Gasolina', 14.5, 225, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/suzuki/suzuki_grand_vitara.png', 85, true),
  ('tesla', 'carro', 'Model 3', 'Tesla Model 3', 2026, 2000, 'Eléctrico', 14.5, 280, 'Líquido Refrigerante Batería EV', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/tesla/tesla_model_3.png', 85, true),
  ('volkswagen', 'carro', 'Jetta', 'Volkswagen Jetta', 2023, 1400, 'Gasolina', 14.5, 120, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/volkswagen/volkswagen_jetta.png', 85, true),
  ('volkswagen', 'carro', 'Virtus', 'Volkswagen Virtus', 2022, 1600, 'Gasolina', 14.5, 120, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/volkswagen/volkswagen_virtus.png', 85, true),
  ('volvo', 'carro', 'Ec40', 'Volvo Ec40', 2026, 2000, 'Eléctrico', 14.5, 280, 'Líquido Refrigerante Batería EV', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/volvo/volvo_ec40_recharge_el_ctrico.png', 85, true),
  ('volvo', 'carro', 'Xc40', 'Volvo Xc40', 2021, 2000, 'Gasolina', 14.5, 180, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/volvo/volvo_xc40_recharge.png', 85, true),
  ('volvo', 'carro', 'Xc60', 'Volvo Xc60', 2025, 2000, 'Híbrido', 14.5, 180, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/volvo/volvo_xc60_recharge.png', 85, true),
  ('audi', 'carro', 'Q5', 'Audi Q5', 2025, 2000, 'Híbrido', 14.5, 125.0, '5W-30 Sintético API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/audi/audi_q5.png', 85, true),
  ('bmw', 'carro', 'X2', 'Bmw X2', 2022, 2000, 'Gasolina', 14.5, 125.0, '5W-30 Sintético API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/bmw/bmw_x2.png', 85, true),
  ('byd', 'carro', 'Qin Plus', 'Byd Qin Plus', 2024, 1500, 'Híbrido', 14.5, 125.0, '5W-30 Sintético API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/byd/byd_qin_plus.png', 85, true),
  ('byd', 'carro', 'Seagull', 'Byd Seagull', 2026, 0, 'Eléctrico', 14.5, 180.0, 'Líquido Refrigerante Batería EV', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/byd/byd_seagull.png', 85, true),
  ('byd', 'carro', 'Song Pro', 'Byd Song Pro', 2025, 1500, 'Híbrido', 14.5, 125.0, '5W-30 Sintético API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/byd/byd_song_pro.png', 85, true),
  ('byd', 'carro', 'Yuan Plus', 'Byd Yuan Plus', 2026, 0, 'Eléctrico', 14.5, 180.0, 'Líquido Refrigerante Batería EV', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/byd/byd_yuan_plus.png', 85, true),
  ('changan', 'carro', 'CS-55 Plus', 'Changan CS-55 Plus', 2024, 1500, 'Gasolina', 14.5, 140.0, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/changan/changan_cs_55_plus.png', 85, true),
  ('chery', 'carro', 'EQ7', 'Chery EQ7', 2026, 0, 'Eléctrico', 14.5, 180.0, 'Líquido Refrigerante Batería EV', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/chery/chery_eq7.png', 85, true),
  ('chery', 'carro', 'Tiggo 4', 'Chery Tiggo 4', 2025, 1500, 'Híbrido', 14.5, 125.0, '5W-30 Sintético API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/chery/chery_tiggo_4.png', 85, true),
  ('chevrolet', 'carro', 'Cruze', 'Chevrolet Cruze', 2015, 1800, 'Híbrido', 14.5, 125.0, '5W-30 Sintético API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/chevrolet/chevrolet_cruze.png', 85, true),
  ('chevrolet', 'carro', 'Joy', 'Chevrolet Joy', 2023, 1400, 'Híbrido', 14.5, 140.0, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/chevrolet/chevrolet_joy.png', 85, true),
  ('citroen', 'carro', 'C3 Aircross', 'Citroën C3 Aircross', 2025, 1000, 'Gasolina', 14.5, 140.0, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/citroen/citroen_c3_aircross.png', 85, true),
  ('deepal', 'carro', 'S07', 'Deepal S07', 2026, 1500, 'Híbrido', 14.5, 125.0, '5W-30 Sintético API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/deepal/deepal_s07.png', 85, true),
  ('ford', 'carro', 'Fiesta', 'Ford Fiesta', 2015, 1600, 'Gasolina', 14.5, 125.0, '5W-30 Sintético API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/ford/ford_fiesta.png', 85, true),
  ('haval', 'carro', 'H6', 'Haval H6', 2024, 1500, 'Híbrido', 14.5, 140.0, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/haval/haval_h6.png', 85, true),
  ('honda', 'carro', 'CR-V', 'Honda CR-V', 2025, 1500, 'Gasolina', 14.5, 125.0, '5W-30 Sintético API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/honda/honda_cr_v.png', 85, true),
  ('honda', 'carro', 'HR-V', 'Honda HR-V', 2022, 1800, 'Gasolina', 14.5, 125.0, '5W-30 Sintético API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/honda/honda_hr_v.png', 85, true),
  ('hyundai', 'carro', 'HB20 Graviti', 'Hyundai HB20 Graviti', 2023, 1600, 'Gasolina', 14.5, 125.0, '5W-30 Sintético API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/hyundai/hyundai_hb20_graviti.png', 85, true),
  ('hyundai', 'carro', 'Kona', 'Hyundai Kona', 2023, 1600, 'Híbrido', 14.5, 125.0, '5W-30 Sintético API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/hyundai/hyundai_kona.png', 85, true),
  ('hyundai', 'carro', 'Staria', 'Hyundai Staria', 2024, 2200, 'Diésel', 14.5, 170.0, '5W-30 Sintético Low SAPS DPF', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/hyundai/hyundai_staria.png', 85, true),
  ('jeep', 'carro', 'Compass', 'Jeep Compass', 2025, 1300, 'Gasolina', 14.5, 140.0, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/jeep/jeep_compass.png', 85, true),
  ('jeep', 'carro', 'Renegade', 'Jeep Renegade', 2022, 1800, 'Gasolina', 14.5, 125.0, '5W-30 Sintético API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/jeep/jeep_renegade.png', 85, true),
  ('jmc', 'carro', 'JMEV EV3', 'Jmc JMEV EV3', 2024, 0, 'Eléctrico', 14.5, 180.0, 'Líquido Refrigerante Batería EV', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/jmc/jmc_jmev_ev3.png', 85, true),
  ('kia', 'carro', 'Soluto', 'Kia Soluto', 2026, 1400, 'Gasolina', 14.5, 140.0, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/kia/kia_soluto.png', 85, true),
  ('mini', 'carro', 'Cooper', 'Mini Cooper', 2022, 1500, 'Gasolina', 14.5, 125.0, '5W-30 Sintético API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/mini/mini_cooper.png', 85, true),
  ('mitsubishi', 'carro', 'ASX', 'Mitsubishi ASX', 2024, 2000, 'Gasolina', 14.5, 125.0, '5W-30 Sintético API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/mitsubishi/mitsubishi_asx.png', 85, true),
  ('opel', 'carro', 'Rocks-e', 'Opel Rocks-e', 2025, 0, 'Eléctrico', 14.5, 180.0, 'Líquido Refrigerante Batería EV', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/opel/opel_rocks_e.png', 85, true),
  ('renault', 'carro', 'Arkana', 'Renault Arkana', 2026, 1300, 'Híbrido', 14.5, 140.0, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/renault/renault_arkana.png', 85, true),
  ('seat', 'carro', 'Arona', 'Seat Arona', 2022, 1600, 'Gasolina', 14.5, 125.0, '5W-30 Sintético API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/seat/seat_arona.png', 85, true),
  ('seat', 'carro', 'Ibiza', 'Seat Ibiza', 2026, 1600, 'Gasolina', 14.5, 125.0, '5W-30 Sintético API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/seat/seat_ibiza.png', 85, true),
  ('suzuki', 'carro', 'Baleno', 'Suzuki Baleno', 2024, 1400, 'Gasolina', 14.5, 140.0, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/suzuki/suzuki_baleno.png', 85, true),
  ('suzuki', 'carro', 'Fronx', 'Suzuki Fronx', 2026, 1500, 'Híbrido', 14.5, 125.0, '5W-30 Sintético API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/suzuki/suzuki_fronx.png', 85, true),
  ('tesla', 'carro', 'Model Y', 'Tesla Model Y', 2026, 0, 'Eléctrico', 14.5, 180.0, 'Líquido Refrigerante Batería EV', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/tesla/tesla_model_y.png', 85, true),
  ('volkswagen', 'carro', 'Golf', 'Volkswagen Golf', 2018, 1400, 'Gasolina', 14.5, 140.0, '0W-20 Sintético Dexos 1 / API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/volkswagen/volkswagen_golf.png', 85, true),
  ('volkswagen', 'carro', 'Voyage', 'Volkswagen Voyage', 2022, 1600, 'Gasolina', 14.5, 125.0, '5W-30 Sintético API SP', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/volkswagen/volkswagen_voyage.png', 85, true)
ON CONFLICT (marca_id, tipo, linea) DO UPDATE SET
  modelo = EXCLUDED.modelo,
  imagen_url = EXCLUDED.imagen_url,
  cilindraje_cc = EXCLUDED.cilindraje_cc,
  tipo_combustible = EXCLUDED.tipo_combustible,
  aceite_recomendado = EXCLUDED.aceite_recomendado,
  activo = true;

-- PASO 4: ACTUALIZACIÓN AUTOMÁTICA OTA (v1.2.12 Build 29)
INSERT INTO public.app_versions (version_code, version_name, zip_url, release_notes, is_mandatory, min_supported_version)
VALUES (
  29,
  '1.2.12',
  'https://github.com/INGJUANRUIZTOBON/my_auto_guide/releases/download/1.1.0/app-release.apk',
  '• Catálogo Expandido Autonal & Autoland: 32 marcas y 87 modelos con siluetas transparentes de alta resolución.\n• Nuevas Marcas Oficiales: Changan, Chery, Deepal, Haval, Honda (Línea Carros), JMC y Opel.\n• Modelos Iconos Añadidos: BYD Seagull, Yuan Plus, Qin Plus; Chery Tiggo 4; Suzuki Baleno, Fronx; VW Golf, Voyage; Audi Q5, BMW X2, Ford Fiesta.\n• Arquitectura de Base de Datos Reforzada: Corrección de restricción única e indexación de alto rendimiento en Supabase.',
  true,
  1
)
ON CONFLICT (version_code) DO UPDATE SET
  version_name = EXCLUDED.version_name,
  zip_url = EXCLUDED.zip_url,
  release_notes = EXCLUDED.release_notes,
  is_mandatory = true;
