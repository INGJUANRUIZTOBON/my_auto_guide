-- =============================================================================
-- SUPABASE CATALOGO BACKUP & SYNC - MY AUTO GUIDE
-- Total Marcas: 22 | Total Modelos: 127
-- =============================================================================

-- 1. ACTUALIZAR LOGOS LIMPIOS DE MARCAS
UPDATE catalogo_marcas SET logo_url = 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/bajaj_logo.png', color_hex = '#0047BA' WHERE id = 'bajaj';
UPDATE catalogo_marcas SET logo_url = 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/renault_logo.png', color_hex = '#FFCC00' WHERE id = 'renault';
UPDATE catalogo_marcas SET logo_url = 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/chevrolet_logo.png', color_hex = '#CD9834' WHERE id = 'chevrolet';
UPDATE catalogo_marcas SET logo_url = 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/toyota_logo.png', color_hex = '#EB0A1E' WHERE id = 'toyota';
UPDATE catalogo_marcas SET logo_url = 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/yamaha_logo.png', color_hex = '#D31145' WHERE id = 'yamaha';
UPDATE catalogo_marcas SET logo_url = 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/akt_logo.png', color_hex = '#E31E24' WHERE id = 'akt';
UPDATE catalogo_marcas SET logo_url = 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/mazda_logo.png', color_hex = '#1B365D' WHERE id = 'mazda';
UPDATE catalogo_marcas SET logo_url = 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/suzuki_logo.png', color_hex = '#E30613' WHERE id = 'suzuki';
UPDATE catalogo_marcas SET logo_url = 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/honda_logo.png', color_hex = '#CC0000' WHERE id = 'honda';
UPDATE catalogo_marcas SET logo_url = 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/kia_logo.png', color_hex = '#05141F' WHERE id = 'kia';
UPDATE catalogo_marcas SET logo_url = 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/nissan_logo.png', color_hex = '#C3002F' WHERE id = 'nissan';
UPDATE catalogo_marcas SET logo_url = 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/tvs_logo.png', color_hex = '#002B49' WHERE id = 'tvs';
UPDATE catalogo_marcas SET logo_url = 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/volkswagen_logo.png', color_hex = '#001E50' WHERE id = 'volkswagen';
UPDATE catalogo_marcas SET logo_url = 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/ktm_logo.png', color_hex = '#FF6600' WHERE id = 'ktm';
UPDATE catalogo_marcas SET logo_url = 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/hero_logo.png', color_hex = '#ED1C24' WHERE id = 'hero';
UPDATE catalogo_marcas SET logo_url = 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/ford_logo.png', color_hex = '#003478' WHERE id = 'ford';
UPDATE catalogo_marcas SET logo_url = 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/hyundai_logo.png', color_hex = '#002C6C' WHERE id = 'hyundai';
UPDATE catalogo_marcas SET logo_url = 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/kawa_logo.png', color_hex = '#66CC00' WHERE id = 'kawasaki';
UPDATE catalogo_marcas SET logo_url = 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/byd_logo.png', color_hex = '#E60012' WHERE id = 'byd';
UPDATE catalogo_marcas SET logo_url = 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/victori_logo.png', color_hex = '#FFCC00' WHERE id = 'victory';
UPDATE catalogo_marcas SET logo_url = 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/royal-enfield.png', color_hex = '#C8102E' WHERE id = 'royal_enfield';
UPDATE catalogo_marcas SET logo_url = 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/bmw_logo.png', color_hex = '#0066B1' WHERE id = 'bmw';

-- 2. SINCRONIZAR MODELOS
INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('f0f19d8a-50fb-4527-b967-abd3b3a780e0', 'kia', 'carro', 'Picanto', 'Picanto GT Line / Zenith 1.25', 2018, NULL, 1248, 'Gasolina', 9.2, 83.0, '5W-30 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/kia/picanto.png', 100, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('8ff42d05-069b-4341-b2e6-96f8aae5ef5e', 'bajaj', 'moto', 'Pulsar', 'Pulsar NS 200 FI', 2018, NULL, 199, 'Gasolina', 3.17, 24.1, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/bajaj/pulsar-ns200-fi.png', 100, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('d0e169be-50ff-4a0d-96fd-7f4eda792c3c', 'chevrolet', 'carro', 'Onix', 'Onix Turbo Sedán LTZ', 2020, NULL, 999, 'Gasolina', 11.6, 115.0, '5W-30 Dexos1 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/chevrolet/2024-versiones-onix-turbo-ltz-at.png', 100, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('1ef6ef81-d5cc-438f-99f0-8428f8f59e32', 'mazda', 'carro', 'CX-30', 'CX-30 Grand Touring Híbrida', 2020, NULL, 1998, 'Híbrido', 13.5, 153.0, '0W-20 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/mazda/cx30.png', 100, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('a65625a3-e983-4c94-a5f2-f7b090914737', 'akt', 'moto', 'NKD', 'NKD 125', 2012, NULL, 124, 'Gasolina', 2.77, 10.3, '20W-50 Mineral', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/akt/nkd125.png', 100, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('74f5922d-2bb2-44cf-bbf0-4bc68da1b673', 'toyota', 'carro', 'Corolla Cross', 'Corolla Cross XEI Híbrido', 2021, NULL, 1798, 'Híbrido', 9.5, 126.0, '0W-20 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/toyota/corolla_cross.png', 100, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('c25ca4e4-1f73-43fc-a885-b4081ae0d3c0', 'renault', 'carro', 'Duster', 'Duster Zen / Intens 1.6', 2013, NULL, 1600, 'Gasolina', 13.2, 114.0, '10W-40 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/renault/duster.png', 100, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('5ee619e4-f2cb-43c1-921d-b899d43e0b46', 'yamaha', 'moto', 'MT', 'MT 15', 2020, NULL, 155, 'Gasolina', 2.64, 19.0, '10W-40 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/yamaha/mt15.png', 99, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('16f6a1f4-2442-4646-abba-ca8e25e860fa', 'yamaha', 'moto', 'BWS', 'BWS FI 125', 2016, NULL, 125, 'Gasolina', 1.7, 9.6, '10W-40 Yamalube 4T', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/yamaha/bws125.png', 99, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('acd2ccd8-e762-4fdd-a40a-bd5ccf04f4d5', 'toyota', 'carro', 'Hilux', 'Hilux SRV 2.4 / 2.8 4x4', 2016, NULL, 2755, 'Diésel', 21.1, 201.0, '5W-30 Sintético Diésel', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/toyota/hilux.png', 99, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('afb0acbf-5ef8-48af-b5c7-accdda093b0e', 'chevrolet', 'carro', 'Tracker', 'Tracker Turbo RS', 2021, NULL, 1199, 'Gasolina', 11.6, 132.0, '5W-30 Dexos1 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/chevrolet/tracker-RS.png', 98, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('6cfb7266-de29-448f-a676-0c614400ae2b', 'bajaj', 'moto', 'Boxer', 'Boxer CT 100 KS', 2012, NULL, 102, 'Gasolina', 2.9, 7.6, '20W-50 Mineral', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/bajaj/boxer-ct100-ks.png', 98, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('1d85c333-47ce-4c63-bd74-64a9786b9730', 'mazda', 'carro', 'Mazda 2', 'Mazda 2 Sport Hatchback', 2016, NULL, 1496, 'Gasolina', 11.6, 108.0, '0W-20 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/mazda/mazda2.png', 98, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('a68056ed-faad-4fd6-af7b-8efe2ea35630', 'nissan', 'carro', 'Versa', 'Versa Advance / Exclusive 1.6', 2020, NULL, 1598, 'Gasolina', 10.8, 118.0, '0W-20 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/nissan/versa.png', 98, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('1269c85e-fbfb-427e-8af2-f397ddba63d9', 'renault', 'carro', 'Kwid', 'Kwid Zen / Outsider', 2019, NULL, 999, 'Gasolina', 10.0, 66.0, '10W-40 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/renault/kwid.png', 98, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('76b14252-3931-4c3e-bd16-f54450b67c0d', 'bajaj', 'moto', 'Boxer', 'Boxer CT 100 ES', 2014, NULL, 102, 'Gasolina', 2.9, 7.6, '20W-50 Mineral', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/bajaj/boxer-ct100.png', 97, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('fa470605-0c71-4a2a-a845-6f78bb95d566', 'chevrolet', 'carro', 'Onix', 'Onix Turbo RS Hatchback', 2021, NULL, 999, 'Gasolina', 11.6, 115.0, '5W-30 Dexos1 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/chevrolet/jelly-onix-turbo-rs.png', 97, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('c5b84066-ea5d-40cc-a130-25706e40ffd8', 'toyota', 'carro', 'Land Cruiser', 'Land Cruiser Prado TXL', 2015, NULL, 2755, 'Diésel', 23.0, 201.0, '5W-30 Sintético Diésel', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/toyota/prado.png', 97, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('74874574-99a4-42dc-987b-f372974e1f06', 'mazda', 'carro', 'Mazda 2', 'Mazda 2 Sedán Grand Touring', 2017, NULL, 1496, 'Gasolina', 11.6, 108.0, '0W-20 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/mazda/mazda2sedan.png', 96, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('3c01e3d1-31d9-45b4-8ca2-b80d386e93d1', 'yamaha', 'moto', 'N-Max', 'N-MAX Connected 155', 2016, NULL, 155, 'Gasolina', 1.87, 15.1, '10W-40 Scooter', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/yamaha/nmax.png', 96, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('8b5348f8-1737-45bb-946d-e9b28321cd74', 'suzuki', 'moto', 'Gixxer', 'Gixxer 150 FI', 2016, NULL, 155, 'Gasolina', 3.17, 13.6, '10W-40 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/suzuki/gixxer150.png', 96, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('5328cc50-cf36-451c-8d7f-cfc84621e923', 'renault', 'carro', 'Duster', 'Duster 1.3 Turbo 4x4', 2021, NULL, 1332, 'Gasolina', 13.2, 154.0, '5W-30 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/renault/duster_turbo.png', 96, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('e20975bc-a038-4cbb-a858-d234b8884a97', 'byd', 'carro', 'Dolphin', 'Dolphin Mini 100% EV', 2024, NULL, 0, 'Eléctrico', 3.0, 75.0, 'No Requiere', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/byd/dolphin_mini.png', 96, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('6b245a64-c09e-408c-9f1c-538f3a5f92ba', 'nissan', 'carro', 'Frontier', 'Frontier Pro-4X 2.5 Diésel', 2017, NULL, 2488, 'Diésel', 21.1, 188.0, '5W-30 Diésel', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/nissan/frontier.png', 96, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('a316246a-1f41-4f27-ab6f-a78cc6cefdc7', 'yamaha', 'moto', 'Aerox', 'Aerox 155 Connected', 2022, NULL, 155, 'Gasolina', 1.45, 15.1, '10W-40 Yamalube AT', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/yamaha/aerox155.png', 96, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('ac4fac29-04cd-485d-ad32-ae8a1a2ea2ae', 'suzuki', 'carro', 'Swift', 'Swift Híbrido Sedán / HB', 2021, NULL, 1197, 'Híbrido', 9.8, 89.0, '0W-16 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/suzuki/swift.png', 96, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('b1e94d86-4945-4215-87b1-e1e475e95ac3', 'kia', 'carro', 'Sportage', 'Sportage Zenith 2.0', 2017, NULL, 1999, 'Gasolina', 14.3, 154.0, '5W-30 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/kia/sportage.png', 95, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('5141ae1e-594a-4d93-a24a-b752b01844c1', 'honda', 'moto', 'CB', 'CB 125F', 2016, NULL, 124, 'Gasolina', 2.9, 10.6, '10W-30 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/honda/cb125f.png', 95, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('86fb1896-403b-48fc-a1c8-80c8c4fdf82e', 'nissan', 'carro', 'Kicks', 'Kicks Advance 1.6', 2018, NULL, 1598, 'Gasolina', 10.8, 118.0, '0W-20 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/nissan/kicks.png', 95, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('0543ae5c-a7b8-4d7d-bf6e-72ed2afb9557', 'toyota', 'carro', 'Fortuner', 'Fortuner SW4 2.8 Diésel', 2017, NULL, 2755, 'Diésel', 21.1, 201.0, '5W-30 Sintético Diésel', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/toyota/fortuner.png', 95, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('e4d88ef8-f084-4ba3-a284-b5bdc2836fb8', 'suzuki', 'moto', 'Gixxer', 'Gixxer 250 FI ABS', 2021, NULL, 249, 'Gasolina', 3.17, 26.5, '10W-40 ECSTAR 4T', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/suzuki/gixxer250.png', 95, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('79b69234-26fd-4fee-8158-01a4977be061', 'suzuki', 'moto', 'GN', 'GN 125', 2012, NULL, 124, 'Gasolina', 2.72, 12.5, '20W-50 Mineral', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/suzuki/GN125.png', 95, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('54864059-09f3-4f4d-b2da-79bdc297f8da', 'akt', 'moto', 'CR4', 'CR4 150', 2018, NULL, 149, 'Gasolina', 3.3, 12.0, '20W-50 4T Mineral', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/akt/CR4_150.png', 95, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('338fc958-3759-4d71-bef7-6d5f5d048466', 'volkswagen', 'carro', 'T-Cross', 'T-Cross 1.0 TSI Turbo', 2021, NULL, 999, 'Gasolina', 13.2, 114.0, '5W-40 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/volkswagen/tcross.png', 95, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('35c2a9f6-f54d-4954-b730-ce04ac66306e', 'kia', 'carro', 'Seltos', 'Seltos Emotion / Zenith 1.6 / 2.0', 2020, NULL, 1999, 'Gasolina', 13.2, 147.0, '5W-20 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/kia/seltos.png', 95, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('09793cad-e061-4d7d-a1a3-f38c44be76c3', 'ford', 'carro', 'Ranger', 'Ranger XLT / Limited 4x4', 2016, NULL, 3198, 'Diésel', 21.1, 197.0, '5W-30 Diésel', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/ford/ranger.png', 95, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('4424d184-cb5b-441c-8985-11d2ca8ceac8', 'renault', 'carro', 'Stepway', 'Stepway Intens 1.6', 2015, NULL, 1600, 'Gasolina', 13.2, 111.0, '10W-40 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/renault/stepway.png', 95, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('c94011be-f1ab-497c-87fc-2e151229a77a', 'chevrolet', 'carro', 'Spark', 'Spark GT 1.2', 2012, NULL, 1206, 'Gasolina', 9.2, 80.5, '5W-30 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/chevrolet/spark_gt.png', 95, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('cf110cb0-8c59-4888-8204-8d0d20b36e0a', 'mazda', 'carro', 'CX-5', 'CX-5 Grand Touring 2.5', 2017, NULL, 2488, 'Gasolina', 15.3, 188.0, '0W-20 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/mazda/cx5.png', 95, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('d40bc671-7438-46cd-891b-d5ec08323f4a', 'bajaj', 'moto', 'Pulsar', 'Pulsar NS 160 FI', 2019, NULL, 160, 'Gasolina', 3.17, 15.8, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/bajaj/pulsar-ns160-fi.png', 95, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('3fdc88b7-733e-409a-bba2-71ee7fda78e2', 'mazda', 'carro', 'Mazda 3', 'Mazda 3 Sedán Híbrido', 2019, NULL, 1998, 'Híbrido', 13.5, 153.0, '0W-20 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/mazda/mazda3.png', 94, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('3801dcb1-77b1-405d-87bf-559f5fb1d4f0', 'byd', 'carro', 'Song Plus', 'Song Plus DM-i Híbrido Enchufable', 2022, NULL, 1498, 'Híbrido', 15.8, 214.0, '0W-20 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/byd/song_plus.png', 94, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('56409c67-24bd-4fa1-b2cf-fcec067dcec9', 'ford', 'carro', 'Escape', 'Escape Titanium Híbrida', 2020, NULL, 2488, 'Híbrido', 14.3, 200.0, '0W-20 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/ford/escape.png', 94, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('7c51a4df-6fc4-4270-b5e2-12261c6f1b59', 'renault', 'carro', 'Sandero', 'Sandero Life / Zen', 2012, NULL, 1600, 'Gasolina', 13.2, 111.0, '10W-40 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/renault/sandero.png', 94, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('14b2238e-216a-456d-aa5c-9dc1a7e50fe6', 'toyota', 'carro', 'Corolla Cross', 'Corolla Cross GR-S', 2022, NULL, 1987, 'Gasolina', 12.4, 168.0, '0W-20 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/toyota/corolla_cross_gr-s.png', 94, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('041fd7b4-c916-42e9-9fd7-7a41c1e9a661', 'tvs', 'moto', 'Apache', 'Apache RTR 160 4V FI', 2019, NULL, 159, 'Gasolina', 3.17, 17.3, '10W-30 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/tvs/apache160.png', 94, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('53032e15-1a87-464b-93a8-fdb8b9375813', 'yamaha', 'moto', 'FZ', 'FZ 25', 2018, NULL, 249, 'Gasolina', 3.7, 20.6, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/yamaha/fz25.png', 94, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('d6af3a22-c0e6-4993-a2f2-03eb0e798b17', 'victory', 'moto', 'One', 'Victory One MP 100', 2019, NULL, 99, 'Gasolina', 2.6, 7.4, '20W-50 4T Mineral', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/victori/victori_one_mp.png', 94, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('38d4d0ec-1585-4c3d-bf4a-37d910e5c844', 'volkswagen', 'carro', 'Gol', 'Gol Trendline 1.6', 2014, NULL, 1598, 'Gasolina', 14.5, 101.0, '5W-40 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/volkswagen/gol.png', 94, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('1b96bc8e-deb3-42bd-9218-2437aa18bd1f', 'suzuki', 'carro', 'Jimny', 'Jimny GLX 1.5 4x4', 2019, NULL, 1462, 'Gasolina', 10.5, 100.0, '0W-20 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/suzuki/jimny.png', 94, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('173eb281-e605-4bb6-881b-36d0868affab', 'yamaha', 'moto', 'XTZ', 'XTZ 250 Lander ABS', 2020, NULL, 249, 'Gasolina', 3.6, 20.4, '20W-50 Yamalube 4T', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/yamaha/xtz250.png', 94, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('b54164c2-6dd5-4897-a3c8-00f7e337708c', 'hyundai', 'carro', 'Grand i10', 'Grand i10 HB20 1.25 / 1.6', 2016, NULL, 1591, 'Gasolina', 11.3, 121.0, '5W-30 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/hyundai/hb20.png', 93, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('543e22c3-4131-4b9b-9ffd-f7d3847ed982', 'suzuki', 'carro', 'Vitara', 'Vitara Live AllGrip', 2017, NULL, 1586, 'Gasolina', 12.4, 115.0, '5W-30 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/suzuki/vitara.png', 93, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('2f10868e-0f8a-4c0a-a54a-14303d15edb3', 'tvs', 'moto', 'Apache', 'Apache RTR 200 4V FI', 2018, NULL, 197, 'Gasolina', 3.17, 20.5, '10W-30 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/tvs/apache200.png', 93, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('66fe8862-23f6-44fa-b4c3-e5d23a6eea58', 'toyota', 'carro', 'Corolla', 'Corolla Sedán SEG Híbrido', 2020, NULL, 1798, 'Híbrido', 11.3, 126.0, '0W-20 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/toyota/corolla.png', 93, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('3232aac0-2d92-4d4d-b21c-8fd2610b9b25', 'chevrolet', 'carro', 'Sail', 'Sail LTZ 1.4', 2013, NULL, 1399, 'Gasolina', 11.0, 102.0, '10W-30 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/chevrolet/sail.png', 93, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('4d0c1b5a-038b-4245-be78-cfa4c7f0d22b', 'honda', 'moto', 'XR', 'XR 150L', 2015, NULL, 149, 'Gasolina', 3.17, 12.1, '10W-30 Mineral', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/honda/xr150l.png', 93, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('e4927c45-d88f-4a49-884b-6193b5212546', 'akt', 'moto', 'NKD', 'NKD 125 Classic', 2020, NULL, 124, 'Gasolina', 2.77, 10.3, '20W-50 Mineral', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/akt/nkd_classic.png', 93, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('5e37e932-9fdc-490c-9565-56930680d0e7', 'kia', 'carro', 'Rio', 'Rio Sedán / HB 1.4', 2018, NULL, 1368, 'Gasolina', 11.8, 99.0, '5W-30 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/kia/rio.png', 93, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('6cc650cd-d1a2-4011-beef-bd72d7508cd0', 'tvs', 'moto', 'Apache', 'Apache RTR 310', 2023, NULL, 312, 'Gasolina', 2.9, 35.6, '10W-50 TRU4 Full Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/tvs/apache310.png', 93, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('81db7685-6133-4f1a-a202-f2a7f55ff1f8', 'yamaha', 'moto', 'FZ', 'FZ 2.0 FI', 2015, NULL, 149, 'Gasolina', 3.17, 13.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/yamaha/fz2.0.png', 93, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('3c9b739d-2d6c-4a77-9db8-f5321298eabe', 'suzuki', 'moto', 'Gixxer', 'Gixxer SF 250 FI ABS', 2021, NULL, 249, 'Gasolina', 3.17, 26.5, '10W-40 ECSTAR 4T', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/suzuki/gixxersf250.png', 93, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('23abb790-87cf-43f8-a596-bf8323908cba', 'yamaha', 'moto', 'R', 'R15 V4', 2017, NULL, 155, 'Gasolina', 2.9, 18.6, '10W-40 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/yamaha/r15.png', 92, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('3cea07a4-f7cb-4c55-b399-3b0887bdfefd', 'akt', 'moto', 'CR4', 'CR4 200', 2021, NULL, 197, 'Gasolina', 3.3, 16.5, '20W-50 4T Mineral', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/akt/CR4_200.png', 92, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('b5fcc62c-a8e0-4c62-8c88-4670d8e67993', 'toyota', 'carro', 'Yaris', 'Yaris Hatchback XLS', 2018, NULL, 1496, 'Gasolina', 11.1, 106.0, '0W-20 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/toyota/yaris.png', 92, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('a34d72f5-ddd6-4449-9a64-3fe192f66b65', 'ktm', 'moto', 'Duke', 'Duke 200 NG', 2020, NULL, 199, 'Gasolina', 3.54, 25.0, '15W-50 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/ktm/duke200.png', 92, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('7dd4c92a-3f61-4afe-b475-55d641399917', 'renault', 'carro', 'Logan', 'Logan Life / Intens', 2012, NULL, 1600, 'Gasolina', 13.2, 111.0, '10W-40 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/renault/logan.png', 92, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('9359b7f5-56fe-45e4-ad6a-cd846ec0f9b7', 'toyota', 'carro', 'Yaris Cross', 'Yaris Cross XLS Híbrido', 2022, NULL, 1490, 'Híbrido', 9.5, 114.0, '0W-20 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/toyota/yaris_cross.png', 92, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('acec0363-706a-4b4e-b82d-677aab4d10cf', 'kia', 'carro', 'Sonet', 'Sonet Zenith 1.5', 2021, NULL, 1497, 'Gasolina', 11.8, 113.0, '5W-30 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/kia/sonet.png', 92, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('ae8e89e8-fab9-4259-9c90-c1acb859baf7', 'hyundai', 'carro', 'Tucson', 'Tucson Limited 2.0', 2018, NULL, 1999, 'Gasolina', 14.3, 154.0, '5W-30 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/hyundai/tucson.png', 92, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('2372c7ee-d457-4da1-9cef-1783935c18d2', 'suzuki', 'moto', 'DR', 'DR 150', 2019, NULL, 149, 'Gasolina', 3.3, 12.2, '10W-40 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/suzuki/DR.png', 92, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('7c05e887-61e4-4ced-8c2a-13e68ab99e26', 'tvs', 'moto', 'Raider', 'Raider 125', 2022, NULL, 124, 'Gasolina', 2.64, 11.2, '10W-30 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/tvs/raider125.png', 92, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('55289efa-8f00-4640-98cf-d7eaa60218a7', 'bajaj', 'moto', 'Boxer', 'Boxer CT 125 Sport', 2022, NULL, 124, 'Gasolina', 2.9, 10.0, '20W-50 Mineral', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/bajaj/boxer-ct-125-sport.png', 92, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('f8c81eb4-76b7-47d4-86f7-42a5dfd890df', 'kawasaki', 'moto', 'Ninja', 'Ninja 400', 2018, NULL, 399, 'Gasolina', 3.7, 49.0, '10W-40 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/kawasaki/ninja400.png', 91, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('a0f4753d-4b46-49a0-ab36-cd3f78eafc8b', 'mazda', 'carro', 'CX-50', 'CX-50 Grand Touring LX', 2023, NULL, 2488, 'Gasolina', 15.8, 188.0, '0W-20 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/mazda/cx50.png', 91, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('7a35732f-3b2b-4eb7-bdb6-a451f99d394c', 'tvs', 'moto', 'Ronin', 'Ronin 225', 2023, NULL, 225, 'Gasolina', 3.7, 20.4, '10W-40 TRU4 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/tvs/ronin225.png', 91, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('ba38cfa9-3c30-410a-8144-d9899a5822f1', 'chevrolet', 'carro', 'Captiva', 'Captiva Turbo Premier', 2020, NULL, 1451, 'Gasolina', 13.7, 144.0, '5W-30 Dexos1 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/chevrolet/captiva.png', 91, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('c5716b02-106f-4560-a7f1-b77ca0b9d822', 'nissan', 'carro', 'Sentra', 'Sentra SR 2.0', 2021, NULL, 1997, 'Gasolina', 12.4, 145.0, '0W-20 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/nissan/sentra.png', 91, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('37260192-063a-499c-89c0-f3a999134de9', 'honda', 'moto', 'CB', 'CB 160F', 2018, NULL, 162, 'Gasolina', 3.17, 15.0, '10W-30 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/honda/cb160f.png', 91, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('5eb7b870-cbf5-44d1-8cd6-b38e7dd8b21f', 'volkswagen', 'carro', 'Amarok', 'Amarok V6 Highline 4x4', 2018, NULL, 2967, 'Diésel', 21.1, 258.0, '5W-30 Diésel', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/volkswagen/amarok.png', 91, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('4b0067b5-ab0a-45b1-9b9e-d323418c709d', 'suzuki', 'moto', 'Gixxer', 'Gixxer SF 150 FI', 2017, NULL, 155, 'Gasolina', 3.17, 13.6, '10W-40 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/suzuki/gixxersf150.png', 91, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('22c255f9-c3d6-4d22-b1f6-5addd335b811', 'yamaha', 'moto', 'XTZ', 'XTZ 150', 2019, NULL, 149, 'Gasolina', 3.17, 12.3, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/yamaha/XTZ150.png', 91, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('0cee284c-747e-4577-8885-f236dbfb09e6', 'akt', 'moto', 'TT', 'TT Dual Sport 200', 2018, NULL, 197, 'Gasolina', 3.17, 16.5, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/akt/tt200.png', 90, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('840a3527-8384-4723-bd3f-69be29594007', 'honda', 'moto', 'CB', 'CB 190R', 2017, NULL, 184, 'Gasolina', 3.17, 15.8, '10W-30 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/honda/cb190r.png', 90, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('b488b587-7dfc-47ca-8268-bb3b08a939bb', 'toyota', 'carro', 'Land Cruiser', 'Land Cruiser 300 GR-S', 2022, NULL, 3346, 'Diésel', 29.0, 302.0, '5W-30 Sintético Diésel', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/toyota/landcruiser300.png', 90, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('bf6d2a32-8142-4410-8181-f813505d9cc6', 'bajaj', 'moto', 'Pulsar', 'Pulsar N250', 2022, NULL, 249, 'Gasolina', 3.7, 24.5, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/bajaj/Pulsar-N250.png', 90, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('8ad252db-019c-4a8b-9445-803c33d6ddc1', 'ktm', 'moto', 'Duke', 'Duke 390', 2018, NULL, 373, 'Gasolina', 3.54, 43.5, '15W-50 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/ktm/duke390.png', 90, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('2e71254f-5a26-4db4-a97c-a7b6f03bde23', 'ford', 'carro', 'Explorer', 'Explorer Limited 2.3 EcoBoost', 2018, NULL, 2296, 'Gasolina', 19.3, 300.0, '5W-30 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/ford/explorer.png', 90, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('58d5adfe-cd63-4fcb-a672-35f74e446347', 'yamaha', 'moto', 'MT', 'MT 09 ABS', 2019, NULL, 890, 'Gasolina', 3.7, 119.0, '10W-40 Yamalube Full Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/yamaha/mt09.png', 90, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('0b0a13c1-7022-4c15-a5bc-e422097471b1', 'akt', 'moto', 'TTR', 'TTR 125', 2017, NULL, 124, 'Gasolina', 2.9, 10.0, '20W-50 4T Mineral', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/akt/ttr125.png', 90, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('e56dbd3e-791d-416d-8bfd-f64765876574', 'suzuki', 'moto', 'Address', 'Address 125 FI', 2022, NULL, 124, 'Gasolina', 1.37, 8.7, '10W-40 Scooter', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/suzuki/address125.png', 90, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('bb93eb70-98ef-4279-a892-97316a3c19bf', 'victory', 'moto', 'Venom', 'Victory Venom 150', 2020, NULL, 149, 'Gasolina', 3.1, 11.5, '20W-50 4T Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/victori/victori_venom_150.png', 90, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('37cddb57-dae3-4e0c-b832-a000002bfa90', 'chevrolet', 'carro', 'Colorado', 'Colorado High Country 2.8 TD', 2018, NULL, 2776, 'Diésel', 19.8, 200.0, '5W-30 Dexos2 Diésel', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/chevrolet/colorado.png', 89, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('54eca475-f3a6-4c15-aa6a-f11c9305f926', 'suzuki', 'moto', 'Burgman', 'Burgman 125 FI', 2021, NULL, 124, 'Gasolina', 1.45, 8.6, '10W-40 Scooter', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/suzuki/burgman.png', 89, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('78a84d38-7b1a-4c97-b67c-45947a5d12b4', 'kawasaki', 'moto', 'Z', 'Z 400', 2019, NULL, 399, 'Gasolina', 3.7, 49.0, '10W-40 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/kawasaki/z400.png', 89, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('1c1ed405-7399-4aa3-ad43-1aee0c71c8fa', 'tvs', 'moto', 'NTorq', 'NTorq 125 Race Edition', 2020, NULL, 124, 'Gasolina', 1.53, 9.4, '10W-30 Scooter', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/tvs/ntorq125.png', 89, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('e671e22a-6b22-4bd1-bc4f-29b712b7ac32', 'yamaha', 'moto', 'Crypton', 'Crypton FI 115', 2014, NULL, 114, 'Gasolina', 1.1, 8.6, '20W-50 Mineral', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/yamaha/cripton.png', 89, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('3335f853-a492-49b3-801a-1b85f35d1a3c', 'bajaj', 'moto', 'Dominar', 'Dominar 400 Touring', 2019, NULL, 373, 'Gasolina', 3.43, 40.0, '10W-50 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/bajaj/Dominar-400-touring.png', 89, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('2a53db99-e01a-4791-b7b0-72cff7b543ae', 'honda', 'moto', 'XR', 'XR 190L', 2017, NULL, 184, 'Gasolina', 3.17, 15.6, '10W-30 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/honda/xr190l.png', 89, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('ded01fe2-a18a-4004-98e3-337a46aaa49d', 'akt', 'moto', 'Special', 'Special 100', 2015, NULL, 99, 'Gasolina', 2.1, 7.2, '20W-50 4T Mineral', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/akt/special100.png', 88, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('daab868c-3f70-4eb5-9322-3794ca902e6c', 'honda', 'moto', 'Dio', 'Dio 110', 2016, NULL, 109, 'Gasolina', 1.4, 7.8, '10W-30 Scooter', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/honda/dio110.png', 88, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('f426cf7e-a7d1-48e0-bae1-1ea5074ec7f0', 'ktm', 'moto', 'Duke', 'Duke 250', 2021, NULL, 248, 'Gasolina', 3.54, 30.0, '15W-50 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/ktm/duke250.png', 88, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('463b671d-c22b-49d8-86ab-0252ba2446b0', 'suzuki', 'moto', 'V-Strom', 'V-STROM 250 SX', 2022, NULL, 249, 'Gasolina', 3.17, 26.5, '10W-40 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/suzuki/VSTROM-250-SX.png', 88, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('d1b688fa-da4f-41a5-a506-fcb99a24e56e', 'chevrolet', 'carro', 'Equinox', 'Equinox RS Turbo', 2019, NULL, 1490, 'Gasolina', 14.8, 170.0, '5W-30 Dexos1 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/chevrolet/equinox-rs-blazer-rs.png', 88, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('3e8d8944-3787-4467-b2f1-1791a43bc9f2', 'kawasaki', 'moto', 'Versys', 'Versys 650', 2016, NULL, 649, 'Gasolina', 5.54, 67.0, '10W-40 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/kawasaki/versys650.png', 88, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('196bb991-2d04-4abc-8ad3-851c9d43351b', 'bajaj', 'moto', 'Pulsar', 'Pulsar N160', 2023, NULL, 164, 'Gasolina', 3.7, 16.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/bajaj/pulsar-n160.png', 88, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('a349e25d-e40d-4b5a-8723-a8c38163adbe', 'chevrolet', 'carro', 'Montana', 'Montana Premier 1.2 Turbo', 2023, NULL, 1199, 'Gasolina', 11.6, 130.0, '0W-20 Dexos 1 Gen 3', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/chevrolet/Montana.png', 88, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('cb644790-dd9d-4618-9729-1d939ecb80b8', 'ktm', 'moto', 'Duke', 'Duke 990', 2024, NULL, 947, 'Gasolina', 3.8, 123.0, '10W-50 Motorex Cross Power 4T', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/ktm/KTM-990-DUKE.png', 88, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('e382b3fd-aafc-4b5a-a48e-5022bee11a89', 'suzuki', 'moto', 'Viva R', 'Viva R Style 115', 2014, NULL, 113, 'Gasolina', 1.13, 9.1, '20W-50 Mineral', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/suzuki/vivarstyle115.png', 87, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('5436c2f5-6f8f-49c6-aa9f-da09e1ca36c0', 'ktm', 'moto', 'Adventure', '390 Adventure', 2020, NULL, 373, 'Gasolina', 3.83, 43.5, '15W-50 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/ktm/390adv.png', 87, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('5884f28b-6eeb-4f5c-a4cb-8ffb2dc8dbe9', 'akt', 'moto', 'CR4', 'CR4 125', 2018, NULL, 124, 'Gasolina', 2.9, 10.0, '20W-50 Mineral', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/akt/cr4_125.png', 87, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('61a78c6f-4bea-4246-b68f-11cc335bc35d', 'honda', 'moto', 'Navi', 'Navi 110', 2018, NULL, 109, 'Gasolina', 1.0, 7.9, '10W-30 Scooter', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/honda/navi110.png', 87, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('71f746c2-8655-40a0-b0f8-11e335eabf85', 'akt', 'moto', '250', '250 R', 2023, NULL, 249, 'Gasolina', 3.4, 25.0, '10W-40 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/akt/250R.png', 86, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('1be46892-a3e1-4cad-89a8-33371b9a7290', 'bajaj', 'moto', 'Boxer', 'Boxer 150X', 2017, NULL, 144, 'Gasolina', 2.9, 12.0, '20W-50 Mineral', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/bajaj/boxer-150x.png', 86, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('85900c83-7ca9-45c5-bd32-37f0f6a90e5b', 'bmw', 'moto', 'G', 'G 310 GS', 2018, NULL, 313, 'Gasolina', 2.9, 34.0, '5W-40 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/bmw/g310gs.png', 86, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('035e3717-b336-472e-bc77-849aed5bc502', 'ktm', 'moto', 'Super Duke', '1390 Super Duke R 2025', 2024, NULL, 1350, 'Gasolina', 4.6, 190.0, '10W-50 Motorex Power Synt 4T', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/ktm/KTM1390superduke2025.png', 85, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('7dbc200a-61f5-4611-9119-bb16c1a68a9f', 'toyota', 'carro', 'Tundra', 'Tundra Platinum 3.5 V6 i-FORCE', 2022, NULL, 3444, 'Gasolina', 32.2, 389.0, '0W-20 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/toyota/tundra.png', 85, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('9924096c-f835-460b-ae3b-6b0649432879', 'akt', 'moto', 'Mawi', 'Mawi 125', 2022, NULL, 124, 'Gasolina', 1.5, 7.1, '10W-40 AT', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/akt/mawi.png', 85, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('0366f22f-0e31-45df-a21f-0892efc84a19', 'suzuki', 'moto', 'Hayabusa', 'Hayabusa GSX 1300R', 2021, NULL, 1340, 'Gasolina', 5.28, 190.0, '10W-40 Full Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/suzuki/hayabusa.png', 85, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('0cf77e4f-4838-463c-aca5-dfb886f76ebb', 'bajaj', 'moto', 'Pulsar', 'Pulsar NS 125', 2020, NULL, 124, 'Gasolina', 2.77, 12.0, '20W-50 Mineral', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/bajaj/pulsar-ns-125.png', 85, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('520d0140-842e-4ca4-8819-50d800a358ee', 'renault', 'carro', 'Koleos', 'Koleos Intens 2.5', 2017, NULL, 2488, 'Gasolina', 15.8, 170.0, '5W-30 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/renault/koleos.png', 85, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('23e6d1ec-bdd8-43c0-b5bd-4b18ea253c89', 'akt', 'moto', 'Dynamic', 'Dynamic Pro 125', 2017, NULL, 124, 'Gasolina', 1.32, 8.9, '10W-40 Scooter', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/akt/dynamic125.png', 85, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('c51717d8-f269-4548-af26-64e93f2ea1dc', 'bajaj', 'moto', 'Dominar', 'Dominar 250', 2020, NULL, 248, 'Gasolina', 3.43, 27.0, '10W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/bajaj/Dominar-250.png', 84, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('829ab184-36a5-46e1-adf4-b6f84a781180', 'bmw', 'moto', 'F', 'F 900 R', 2020, NULL, 895, 'Gasolina', 3.43, 105.0, '5W-40 Sintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/bmw/f900r.png', 84, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('6ef28efe-9320-4592-8ca1-c56061ef8982', 'chevrolet', 'carro', 'Traverse', 'Traverse RS 3.6 V6 AWD', 2018, NULL, 3564, 'Gasolina', 21.7, 310.0, '5W-30 Dexos 1', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/chevrolet/traverse.png', 82, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('72b6934a-545a-4254-b67a-e0e0fc17a5c8', 'bajaj', 'moto', 'Discover', 'Discover 125', 2015, NULL, 124, 'Gasolina', 2.11, 11.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/bajaj/discover-125.png', 82, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;

INSERT INTO catalogo_modelos (id, marca_id, tipo, linea, modelo, anio_inicio, anio_fin, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo)
VALUES ('5460ba44-d18a-4084-933d-6d9d79da9982', 'chevrolet', 'carro', 'Silverado', 'Silverado RST V8 5.3 4x4', 2021, NULL, 5328, 'Gasolina', 24.0, 355.0, '0W-20 Dexos 1', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/carros/chevrolet/silverado.png', 80, true)
ON CONFLICT (id) DO UPDATE SET imagen_url = EXCLUDED.imagen_url, activo = true;
