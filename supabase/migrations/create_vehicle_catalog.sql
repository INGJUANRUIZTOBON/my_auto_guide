-- =============================================================================
-- create_vehicle_catalog.sql — CATÁLOGO AUTOMOTRIZ CLOUD COLOMBIA
-- =============================================================================
-- Ejecutar en Supabase Dashboard -> SQL Editor.
-- Crea las tablas de Marcas, Modelos, Índices de búsqueda, Seguridad RLS,
-- Bucket de Storage y el Seed inicial con las marcas y modelos más vendidos de Colombia.

-- 1. EXTENSIÓN PARA BÚSQUEDA RÁPIDA (Trigram)
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- 2. TABLA DE MARCAS
CREATE TABLE IF NOT EXISTS public.catalogo_marcas (
    id TEXT PRIMARY KEY, -- 'yamaha', 'bajaj', 'toyota', 'chevrolet', etc.
    nombre TEXT NOT NULL,
    tipo TEXT NOT NULL CHECK (tipo IN ('moto', 'carro', 'ambos')),
    logo_url TEXT NOT NULL,
    color_hex TEXT DEFAULT '#00E5FF',
    pais_origen TEXT DEFAULT '',
    popularidad INTEGER DEFAULT 0,
    activo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. TABLA DE MODELOS CON ESPECIFICACIONES TÉCNICAS
CREATE TABLE IF NOT EXISTS public.catalogo_modelos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    marca_id TEXT NOT NULL REFERENCES public.catalogo_marcas(id) ON DELETE CASCADE,
    tipo TEXT NOT NULL CHECK (tipo IN ('moto', 'carro')),
    linea TEXT NOT NULL,
    modelo TEXT NOT NULL,
    anio_inicio INTEGER DEFAULT 2012,
    anio_fin INTEGER, -- NULL = En producción activa
    cilindraje_cc INTEGER DEFAULT 0,
    tipo_combustible TEXT DEFAULT 'Gasolina' CHECK (tipo_combustible IN ('Gasolina', 'Diésel', 'Híbrido', 'Eléctrico', 'Gas/Gasolina')),
    capacidad_tanque_gal NUMERIC(5,2) DEFAULT 3.0,
    potencia_hp NUMERIC(6,1) DEFAULT 0,
    aceite_recomendado TEXT DEFAULT '20W-50 Semisintético',
    imagen_url TEXT NOT NULL,
    thumbnail_url TEXT,
    specs_adicionales JSONB DEFAULT '{}'::jsonb,
    popularidad INTEGER DEFAULT 0,
    activo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 4. ÍNDICES DE RENDIMIENTO PARA TIEMPO DE RESPUESTA < 10MS
CREATE INDEX IF NOT EXISTS idx_catalogo_marcas_tipo ON public.catalogo_marcas(tipo, popularidad DESC);
CREATE INDEX IF NOT EXISTS idx_catalogo_modelos_marca ON public.catalogo_modelos(marca_id, popularidad DESC);
CREATE INDEX IF NOT EXISTS idx_catalogo_modelos_tipo ON public.catalogo_modelos(tipo);
CREATE INDEX IF NOT EXISTS idx_catalogo_modelos_trgm ON public.catalogo_modelos 
USING gin ((linea || ' ' || modelo) gin_trgm_ops);

-- 5. POLÍTICAS DE ACCESO PÚBLICO (RLS)
ALTER TABLE public.catalogo_marcas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.catalogo_modelos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Lectura pública catalogo_marcas" ON public.catalogo_marcas;
CREATE POLICY "Lectura pública catalogo_marcas"
    ON public.catalogo_marcas FOR SELECT
    TO anon, authenticated
    USING (activo = true);

DROP POLICY IF EXISTS "Lectura pública catalogo_modelos" ON public.catalogo_modelos;
CREATE POLICY "Lectura pública catalogo_modelos"
    ON public.catalogo_modelos FOR SELECT
    TO anon, authenticated
    USING (activo = true);

-- 6. BUCKET CDN PARA IMÁGENES Y LOGOS TRANSPARENTES
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'catalog-assets',
    'catalog-assets',
    true,
    5242880,
    ARRAY['image/webp', 'image/png', 'image/svg+xml', 'image/jpeg']
)
ON CONFLICT (id) DO UPDATE SET public = true;

DROP POLICY IF EXISTS "Acceso público lectura catalog-assets" ON storage.objects;
CREATE POLICY "Acceso público lectura catalog-assets"
    ON storage.objects FOR SELECT
    TO anon, authenticated
    USING (bucket_id = 'catalog-assets');

-- 7. SEED INICIAL: MARCAS LÍDERES EN COLOMBIA
INSERT INTO public.catalogo_marcas (id, nombre, tipo, logo_url, color_hex, pais_origen, popularidad) VALUES
    -- Motos
    ('bajaj', 'Bajaj', 'moto', 'https://raw.githubusercontent.com/INGJUANRUIZTOBON/my_auto_guide/main/assets/logos/bajaj_logo.png', '#0047BA', 'India', 100),
    ('yamaha', 'Yamaha', 'moto', 'https://raw.githubusercontent.com/INGJUANRUIZTOBON/my_auto_guide/main/assets/logos/yamaha_logo.png', '#D31145', 'Japón', 95),
    ('akt', 'AKT Motos', 'moto', 'https://raw.githubusercontent.com/INGJUANRUIZTOBON/my_auto_guide/main/assets/logos/akt_logo.png', '#E31E24', 'Colombia', 92),
    ('suzuki', 'Suzuki', 'ambos', 'https://raw.githubusercontent.com/INGJUANRUIZTOBON/my_auto_guide/main/assets/logos/suzuki_logo.png', '#E30613', 'Japón', 90),
    ('honda', 'Honda', 'ambos', 'https://raw.githubusercontent.com/INGJUANRUIZTOBON/my_auto_guide/main/assets/logos/honda_logo.png', '#CC0000', 'Japón', 88),
    ('tvs', 'TVS', 'moto', 'https://raw.githubusercontent.com/INGJUANRUIZTOBON/my_auto_guide/main/assets/logos/tvs_logo.png', '#002B49', 'India', 85),
    ('ktm', 'KTM', 'moto', 'https://raw.githubusercontent.com/INGJUANRUIZTOBON/my_auto_guide/main/assets/logos/ktm_logo.png', '#FF6600', 'Austria', 82),
    ('hero', 'Hero MotoCorp', 'moto', 'https://raw.githubusercontent.com/INGJUANRUIZTOBON/my_auto_guide/main/assets/logos/hero_logo.png', '#ED1C24', 'India', 80),
    ('kawasaki', 'Kawasaki', 'moto', 'https://raw.githubusercontent.com/INGJUANRUIZTOBON/my_auto_guide/main/assets/logos/kawasaki_logo.png', '#66CC00', 'Japón', 78),
    ('victory', 'Victory', 'moto', 'https://raw.githubusercontent.com/INGJUANRUIZTOBON/my_auto_guide/main/assets/logos/victory_logo.png', '#FFCC00', 'Colombia', 75),
    ('royal_enfield', 'Royal Enfield', 'moto', 'https://raw.githubusercontent.com/INGJUANRUIZTOBON/my_auto_guide/main/assets/logos/royal_enfield_logo.png', '#C8102E', 'Reino Unido / India', 70),
    ('bmw', 'BMW', 'ambos', 'https://raw.githubusercontent.com/INGJUANRUIZTOBON/my_auto_guide/main/assets/logos/bmw_logo.png', '#0066B1', 'Alemania', 65),

    -- Carros
    ('renault', 'Renault', 'carro', 'https://raw.githubusercontent.com/INGJUANRUIZTOBON/my_auto_guide/main/assets/logos/renault_logo.png', '#FFCC00', 'Francia', 100),
    ('chevrolet', 'Chevrolet', 'carro', 'https://raw.githubusercontent.com/INGJUANRUIZTOBON/my_auto_guide/main/assets/logos/chevrolet_logo.png', '#CD9834', 'Estados Unidos', 98),
    ('toyota', 'Toyota', 'carro', 'https://raw.githubusercontent.com/INGJUANRUIZTOBON/my_auto_guide/main/assets/logos/toyota_logo.png', '#EB0A1E', 'Japón', 95),
    ('mazda', 'Mazda', 'carro', 'https://raw.githubusercontent.com/INGJUANRUIZTOBON/my_auto_guide/main/assets/logos/mazda_logo.png', '#1B365D', 'Japón', 92),
    ('kia', 'Kia', 'carro', 'https://raw.githubusercontent.com/INGJUANRUIZTOBON/my_auto_guide/main/assets/logos/kia_logo.png', '#05141F', 'Corea del Sur', 88),
    ('nissan', 'Nissan', 'carro', 'https://raw.githubusercontent.com/INGJUANRUIZTOBON/my_auto_guide/main/assets/logos/nissan_logo.png', '#C3002F', 'Japón', 86),
    ('volkswagen', 'Volkswagen', 'carro', 'https://raw.githubusercontent.com/INGJUANRUIZTOBON/my_auto_guide/main/assets/logos/volkswagen_logo.png', '#001E50', 'Alemania', 84),
    ('ford', 'Ford', 'carro', 'https://raw.githubusercontent.com/INGJUANRUIZTOBON/my_auto_guide/main/assets/logos/ford_logo.png', '#003478', 'Estados Unidos', 80),
    ('hyundai', 'Hyundai', 'carro', 'https://raw.githubusercontent.com/INGJUANRUIZTOBON/my_auto_guide/main/assets/logos/hyundai_logo.png', '#002C6C', 'Corea del Sur', 78),
    ('byd', 'BYD', 'carro', 'https://raw.githubusercontent.com/INGJUANRUIZTOBON/my_auto_guide/main/assets/logos/byd_logo.png', '#E60012', 'China', 75)
ON CONFLICT (id) DO UPDATE SET
    nombre = EXCLUDED.nombre,
    tipo = EXCLUDED.tipo,
    color_hex = EXCLUDED.color_hex,
    popularidad = EXCLUDED.popularidad;

-- 8. SEED INICIAL: MODELOS TOP COLOMBIA CON ESPECIFICACIONES TÉCNICAS
INSERT INTO public.catalogo_modelos 
(marca_id, tipo, linea, modelo, anio_inicio, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad)
VALUES
    -- BAJAJ
    ('bajaj', 'moto', 'Pulsar', 'Pulsar NS 200 FI', 2018, 199, 'Gasolina', 3.17, 24.1, '20W-50 Semisintético', 'assets/motos/bajaj/pulsar-ns200-fi.png', 100),
    ('bajaj', 'moto', 'Pulsar', 'Pulsar NS 160 FI', 2019, 160, 'Gasolina', 3.17, 15.8, '20W-50 Semisintético', 'assets/motos/bajaj/pulsar-ns160-fi.png', 95),
    ('bajaj', 'moto', 'Pulsar', 'Pulsar N250', 2022, 249, 'Gasolina', 3.70, 24.5, '20W-50 Semisintético', 'assets/motos/bajaj/Pulsar-N250.png', 90),
    ('bajaj', 'moto', 'Pulsar', 'Pulsar N160', 2023, 164, 'Gasolina', 3.70, 16.0, '20W-50 Semisintético', 'assets/motos/bajaj/pulsar-n160.png', 88),
    ('bajaj', 'moto', 'Pulsar', 'Pulsar NS 125', 2020, 124, 'Gasolina', 2.77, 12.0, '20W-50 Mineral', 'assets/motos/bajaj/pulsar-ns-125.png', 85),
    ('bajaj', 'moto', 'Boxer', 'Boxer CT 100 KS', 2012, 102, 'Gasolina', 2.90, 7.6, '20W-50 Mineral', 'assets/motos/bajaj/boxer-ct100-ks.png', 98),
    ('bajaj', 'moto', 'Boxer', 'Boxer CT 100 ES', 2014, 102, 'Gasolina', 2.90, 7.6, '20W-50 Mineral', 'assets/motos/bajaj/boxer-ct100.png', 97),
    ('bajaj', 'moto', 'Boxer', 'Boxer CT 125 Sport', 2022, 124, 'Gasolina', 2.90, 10.0, '20W-50 Mineral', 'assets/motos/bajaj/boxer-ct-125-sport.png', 92),
    ('bajaj', 'moto', 'Boxer', 'Boxer 150X', 2017, 144, 'Gasolina', 2.90, 12.0, '20W-50 Mineral', 'assets/motos/bajaj/boxer-150x.png', 86),
    ('bajaj', 'moto', 'Dominar', 'Dominar 400 Touring', 2019, 373, 'Gasolina', 3.43, 40.0, '10W-50 Sintético', 'assets/motos/bajaj/Dominar-400-touring.png', 89),
    ('bajaj', 'moto', 'Dominar', 'Dominar 250', 2020, 248, 'Gasolina', 3.43, 27.0, '10W-50 Semisintético', 'assets/motos/bajaj/Dominar-250.png', 84),
    ('bajaj', 'moto', 'Discover', 'Discover 125', 2015, 124, 'Gasolina', 2.11, 11.0, '20W-50 Semisintético', 'assets/motos/bajaj/discover-125.png', 82),

    -- YAMAHA
    ('yamaha', 'moto', 'MT', 'MT 15', 2020, 155, 'Gasolina', 2.64, 19.0, '10W-40 Sintético', 'assets/motos/yamaha/mt15.png', 99),
    ('yamaha', 'moto', 'FZ', 'FZ 25', 2018, 249, 'Gasolina', 3.70, 20.6, '20W-50 Semisintético', 'assets/motos/yamaha/fz25.png', 94),
    ('yamaha', 'moto', 'FZ', 'FZ 2.0 FI', 2015, 149, 'Gasolina', 3.17, 13.0, '20W-50 Semisintético', 'assets/motos/yamaha/fz2.0.png', 93),
    ('yamaha', 'moto', 'R', 'R15 V4', 2017, 155, 'Gasolina', 2.90, 18.6, '10W-40 Sintético', 'assets/motos/yamaha/r15.png', 92),
    ('yamaha', 'moto', 'N-Max', 'N-MAX Connected 155', 2016, 155, 'Gasolina', 1.87, 15.1, '10W-40 Scooter', 'assets/motos/yamaha/nmax.png', 96),
    ('yamaha', 'moto', 'XTZ', 'XTZ 150', 2019, 149, 'Gasolina', 3.17, 12.3, '20W-50 Semisintético', 'assets/motos/yamaha/XTZ150.png', 91),
    ('yamaha', 'moto', 'Crypton', 'Crypton FI 115', 2014, 114, 'Gasolina', 1.10, 8.6, '20W-50 Mineral', 'assets/motos/yamaha/cripton.png', 89),

    -- AKT
    ('akt', 'moto', 'NKD', 'NKD 125', 2012, 124, 'Gasolina', 2.77, 10.3, '20W-50 Mineral', 'assets/motos/akt/nkd125.png', 100),
    ('akt', 'moto', 'NKD', 'NKD 125 Classic', 2020, 124, 'Gasolina', 2.77, 10.3, '20W-50 Mineral', 'assets/motos/akt/nkd_classic.png', 93),
    ('akt', 'moto', 'TT', 'TT Dual Sport 200', 2018, 197, 'Gasolina', 3.17, 16.5, '20W-50 Semisintético', 'assets/motos/akt/tt200.png', 90),
    ('akt', 'moto', 'CR4', 'CR4 125', 2018, 124, 'Gasolina', 2.90, 10.0, '20W-50 Mineral', 'assets/motos/akt/cr4_125.png', 87),
    ('akt', 'moto', 'Dynamic', 'Dynamic Pro 125', 2017, 124, 'Gasolina', 1.32, 8.9, '10W-40 Scooter', 'assets/motos/akt/dynamic125.png', 85),

    -- SUZUKI (MOTOS)
    ('suzuki', 'moto', 'Gixxer', 'Gixxer 150 FI', 2016, 155, 'Gasolina', 3.17, 13.6, '10W-40 Semisintético', 'assets/motos/suzuki/gixxer150.png', 96),
    ('suzuki', 'moto', 'Gixxer', 'Gixxer SF 150 FI', 2017, 155, 'Gasolina', 3.17, 13.6, '10W-40 Semisintético', 'assets/motos/suzuki/gixxersf150.png', 91),
    ('suzuki', 'moto', 'GN', 'GN 125', 2012, 124, 'Gasolina', 2.72, 12.5, '20W-50 Mineral', 'assets/motos/suzuki/GN125.png', 95),
    ('suzuki', 'moto', 'DR', 'DR 150', 2019, 149, 'Gasolina', 3.30, 12.2, '10W-40 Semisintético', 'assets/motos/suzuki/DR.png', 92),
    ('suzuki', 'moto', 'V-Strom', 'V-STROM 250 SX', 2022, 249, 'Gasolina', 3.17, 26.5, '10W-40 Sintético', 'assets/motos/suzuki/VSTROM-250-SX.png', 88),
    ('suzuki', 'moto', 'Viva R', 'Viva R Style 115', 2014, 113, 'Gasolina', 1.13, 9.1, '20W-50 Mineral', 'assets/motos/suzuki/vivarstyle115.png', 87),

    -- HONDA (MOTOS)
    ('honda', 'moto', 'CB', 'CB 125F', 2016, 124, 'Gasolina', 2.90, 10.6, '10W-30 Semisintético', 'assets/motos/honda/cb125f.png', 95),
    ('honda', 'moto', 'CB', 'CB 160F', 2018, 162, 'Gasolina', 3.17, 15.0, '10W-30 Semisintético', 'assets/motos/honda/cb160f.png', 91),
    ('honda', 'moto', 'CB', 'CB 190R', 2017, 184, 'Gasolina', 3.17, 15.8, '10W-30 Semisintético', 'assets/motos/honda/cb190r.png', 90),
    ('honda', 'moto', 'XR', 'XR 150L', 2015, 149, 'Gasolina', 3.17, 12.1, '10W-30 Mineral', 'assets/motos/honda/xr150l.png', 93),
    ('honda', 'moto', 'XR', 'XR 190L', 2017, 184, 'Gasolina', 3.17, 15.6, '10W-30 Semisintético', 'assets/motos/honda/xr190l.png', 89),
    ('honda', 'moto', 'Dio', 'Dio 110', 2016, 109, 'Gasolina', 1.40, 7.8, '10W-30 Scooter', 'assets/motos/honda/dio110.png', 88),
    ('honda', 'moto', 'Navi', 'Navi 110', 2018, 109, 'Gasolina', 1.00, 7.9, '10W-30 Scooter', 'assets/motos/honda/navi110.png', 87),

    -- TVS
    ('tvs', 'moto', 'Apache', 'Apache RTR 160 4V FI', 2019, 159, 'Gasolina', 3.17, 17.3, '10W-30 Sintético', 'assets/motos/tvs/apache160.png', 94),
    ('tvs', 'moto', 'Apache', 'Apache RTR 200 4V FI', 2018, 197, 'Gasolina', 3.17, 20.5, '10W-30 Sintético', 'assets/motos/tvs/apache200.png', 93),
    ('tvs', 'moto', 'Raider', 'Raider 125', 2022, 124, 'Gasolina', 2.64, 11.2, '10W-30 Semisintético', 'assets/motos/tvs/raider125.png', 92),
    ('tvs', 'moto', 'NTorq', 'NTorq 125 Race Edition', 2020, 124, 'Gasolina', 1.53, 9.4, '10W-30 Scooter', 'assets/motos/tvs/ntorq125.png', 89),

    -- KTM
    ('ktm', 'moto', 'Duke', 'Duke 200 NG', 2020, 199, 'Gasolina', 3.54, 25.0, '15W-50 Sintético', 'assets/motos/ktm/duke200.png', 92),
    ('ktm', 'moto', 'Duke', 'Duke 250', 2021, 248, 'Gasolina', 3.54, 30.0, '15W-50 Sintético', 'assets/motos/ktm/duke250.png', 88),
    ('ktm', 'moto', 'Duke', 'Duke 390', 2018, 373, 'Gasolina', 3.54, 43.5, '15W-50 Sintético', 'assets/motos/ktm/duke390.png', 90),
    ('ktm', 'moto', 'Adventure', '390 Adventure', 2020, 373, 'Gasolina', 3.83, 43.5, '15W-50 Sintético', 'assets/motos/ktm/390adv.png', 87),

    -- KAWASAKI
    ('kawasaki', 'moto', 'Ninja', 'Ninja 400', 2018, 399, 'Gasolina', 3.70, 49.0, '10W-40 Sintético', 'assets/motos/kawasaki/ninja400.png', 91),
    ('kawasaki', 'moto', 'Z', 'Z 400', 2019, 399, 'Gasolina', 3.70, 49.0, '10W-40 Sintético', 'assets/motos/kawasaki/z400.png', 89),
    ('kawasaki', 'moto', 'Versys', 'Versys 650', 2016, 649, 'Gasolina', 5.54, 67.0, '10W-40 Sintético', 'assets/motos/kawasaki/versys650.png', 88),

    -- BMW MOTOS
    ('bmw', 'moto', 'G', 'G 310 GS', 2018, 313, 'Gasolina', 2.90, 34.0, '5W-40 Sintético', 'assets/motos/bmw/g310gs.png', 86),
    ('bmw', 'moto', 'F', 'F 900 R', 2020, 895, 'Gasolina', 3.43, 105.0, '5W-40 Sintético', 'assets/motos/bmw/f900r.png', 84),

    -- RENAULT (CARROS)
    ('renault', 'carro', 'Duster', 'Duster Zen / Intens 1.6', 2013, 1600, 'Gasolina', 13.2, 114.0, '10W-40 Semisintético', 'assets/carros/renault/duster.png', 100),
    ('renault', 'carro', 'Duster', 'Duster 1.3 Turbo 4x4', 2021, 1332, 'Gasolina', 13.2, 154.0, '5W-30 Sintético', 'assets/carros/renault/duster_turbo.png', 96),
    ('renault', 'carro', 'Kwid', 'Kwid Zen / Outsider', 2019, 999, 'Gasolina', 10.0, 66.0, '10W-40 Sintético', 'assets/carros/renault/kwid.png', 98),
    ('renault', 'carro', 'Stepway', 'Stepway Intens 1.6', 2015, 1600, 'Gasolina', 13.2, 111.0, '10W-40 Semisintético', 'assets/carros/renault/stepway.png', 95),
    ('renault', 'carro', 'Sandero', 'Sandero Life / Zen', 2012, 1600, 'Gasolina', 13.2, 111.0, '10W-40 Semisintético', 'assets/carros/renault/sandero.png', 94),
    ('renault', 'carro', 'Logan', 'Logan Life / Intens', 2012, 1600, 'Gasolina', 13.2, 111.0, '10W-40 Semisintético', 'assets/carros/renault/logan.png', 92),
    ('renault', 'carro', 'Koleos', 'Koleos Intens 2.5', 2017, 2488, 'Gasolina', 15.8, 170.0, '5W-30 Sintético', 'assets/carros/renault/koleos.png', 85),

    -- CHEVROLET (CARROS)
    ('chevrolet', 'carro', 'Onix', 'Onix Turbo Sedán LTZ', 2020, 999, 'Gasolina', 11.6, 115.0, '5W-30 Dexos1 Sintético', 'assets/carros/chevrolet/2024-versiones-onix-turbo-ltz-at.png', 100),
    ('chevrolet', 'carro', 'Onix', 'Onix Turbo RS Hatchback', 2021, 999, 'Gasolina', 11.6, 115.0, '5W-30 Dexos1 Sintético', 'assets/carros/chevrolet/jelly-onix-turbo-rs.png', 97),
    ('chevrolet', 'carro', 'Tracker', 'Tracker Turbo RS', 2021, 1199, 'Gasolina', 11.6, 132.0, '5W-30 Dexos1 Sintético', 'assets/carros/chevrolet/tracker-RS.png', 98),
    ('chevrolet', 'carro', 'Spark', 'Spark GT 1.2', 2012, 1206, 'Gasolina', 9.2, 80.5, '5W-30 Sintético', 'assets/carros/chevrolet/spark_gt.png', 95),
    ('chevrolet', 'carro', 'Sail', 'Sail LTZ 1.4', 2013, 1399, 'Gasolina', 11.0, 102.0, '10W-30 Semisintético', 'assets/carros/chevrolet/sail.png', 93),
    ('chevrolet', 'carro', 'Captiva', 'Captiva Turbo Premier', 2020, 1451, 'Gasolina', 13.7, 144.0, '5W-30 Dexos1 Sintético', 'assets/carros/chevrolet/captiva.png', 91),
    ('chevrolet', 'carro', 'Equinox', 'Equinox RS Turbo', 2019, 1490, 'Gasolina', 14.8, 170.0, '5W-30 Dexos1 Sintético', 'assets/carros/chevrolet/equinox-rs-blazer-rs.png', 88),
    ('chevrolet', 'carro', 'Colorado', 'Colorado High Country 2.8 TD', 2018, 2776, 'Diésel', 19.8, 200.0, '5W-30 Dexos2 Diésel', 'assets/carros/chevrolet/colorado.png', 89),

    -- TOYOTA (CARROS)
    ('toyota', 'carro', 'Corolla Cross', 'Corolla Cross XEI Híbrido', 2021, 1798, 'Híbrido', 9.5, 126.0, '0W-20 Sintético', 'assets/carros/toyota/corolla_cross.png', 100),
    ('toyota', 'carro', 'Corolla Cross', 'Corolla Cross GR-S', 2022, 1987, 'Gasolina', 12.4, 168.0, '0W-20 Sintético', 'assets/carros/toyota/corolla_cross_gr-s.png', 94),
    ('toyota', 'carro', 'Hilux', 'Hilux SRV 2.4 / 2.8 4x4', 2016, 2755, 'Diésel', 21.1, 201.0, '5W-30 Sintético Diésel', 'assets/carros/toyota/hilux.png', 99),
    ('toyota', 'carro', 'Fortuner', 'Fortuner SW4 2.8 Diésel', 2017, 2755, 'Diésel', 21.1, 201.0, '5W-30 Sintético Diésel', 'assets/carros/toyota/fortuner.png', 95),
    ('toyota', 'carro', 'Corolla', 'Corolla Sedán SEG Híbrido', 2020, 1798, 'Híbrido', 11.3, 126.0, '0W-20 Sintético', 'assets/carros/toyota/corolla.png', 93),
    ('toyota', 'carro', 'Yaris Cross', 'Yaris Cross XLS Híbrido', 2022, 1490, 'Híbrido', 9.5, 114.0, '0W-20 Sintético', 'assets/carros/toyota/yaris_cross.png', 92),
    ('toyota', 'carro', 'Land Cruiser', 'Land Cruiser Prado TXL', 2015, 2755, 'Diésel', 23.0, 201.0, '5W-30 Sintético Diésel', 'assets/carros/toyota/prado.png', 97),
    ('toyota', 'carro', 'Land Cruiser', 'Land Cruiser 300 GR-S', 2022, 3346, 'Diésel', 29.0, 302.0, '5W-30 Sintético Diésel', 'assets/carros/toyota/landcruiser300.png', 90),

    -- MAZDA (CARROS)
    ('mazda', 'carro', 'CX-30', 'CX-30 Grand Touring Híbrida', 2020, 1998, 'Híbrido', 13.5, 153.0, '0W-20 Sintético', 'assets/carros/mazda/cx30.png', 100),
    ('mazda', 'carro', 'Mazda 2', 'Mazda 2 Sport Hatchback', 2016, 1496, 'Gasolina', 11.6, 108.0, '0W-20 Sintético', 'assets/carros/mazda/mazda2.png', 98),
    ('mazda', 'carro', 'Mazda 2', 'Mazda 2 Sedán Grand Touring', 2017, 1496, 'Gasolina', 11.6, 108.0, '0W-20 Sintético', 'assets/carros/mazda/mazda2sedan.png', 96),
    ('mazda', 'carro', 'Mazda 3', 'Mazda 3 Sedán Híbrido', 2019, 1998, 'Híbrido', 13.5, 153.0, '0W-20 Sintético', 'assets/carros/mazda/mazda3.png', 94),
    ('mazda', 'carro', 'CX-5', 'CX-5 Grand Touring 2.5', 2017, 2488, 'Gasolina', 15.3, 188.0, '0W-20 Sintético', 'assets/carros/mazda/cx5.png', 95),
    ('mazda', 'carro', 'CX-50', 'CX-50 Grand Touring LX', 2023, 2488, 'Gasolina', 15.8, 188.0, '0W-20 Sintético', 'assets/carros/mazda/cx50.png', 91),

    -- KIA (CARROS)
    ('kia', 'carro', 'Picanto', 'Picanto GT Line / Zenith 1.25', 2018, 1248, 'Gasolina', 9.2, 83.0, '5W-30 Sintético', 'assets/carros/kia/picanto.png', 100),
    ('kia', 'carro', 'Sportage', 'Sportage Zenith 2.0', 2017, 1999, 'Gasolina', 14.3, 154.0, '5W-30 Sintético', 'assets/carros/kia/sportage.png', 95),
    ('kia', 'carro', 'Sonet', 'Sonet Zenith 1.5', 2021, 1497, 'Gasolina', 11.8, 113.0, '5W-30 Sintético', 'assets/carros/kia/sonet.png', 92),
    ('kia', 'carro', 'Rio', 'Rio Sedán / HB 1.4', 2018, 1368, 'Gasolina', 11.8, 99.0, '5W-30 Sintético', 'assets/carros/kia/rio.png', 93),

    -- NISSAN (CARROS)
    ('nissan', 'carro', 'Versa', 'Versa Advance / Exclusive 1.6', 2020, 1598, 'Gasolina', 10.8, 118.0, '0W-20 Sintético', 'assets/carros/nissan/versa.png', 98),
    ('nissan', 'carro', 'Kicks', 'Kicks Advance 1.6', 2018, 1598, 'Gasolina', 10.8, 118.0, '0W-20 Sintético', 'assets/carros/nissan/kicks.png', 95),
    ('nissan', 'carro', 'Frontier', 'Frontier Pro-4X 2.5 Diésel', 2017, 2488, 'Diésel', 21.1, 188.0, '5W-30 Diésel', 'assets/carros/nissan/frontier.png', 96),
    ('nissan', 'carro', 'Sentra', 'Sentra SR 2.0', 2021, 1997, 'Gasolina', 12.4, 145.0, '0W-20 Sintético', 'assets/carros/nissan/sentra.png', 91),

    -- SUZUKI (CARROS)
    ('suzuki', 'carro', 'Swift', 'Swift Híbrido Sedán / HB', 2021, 1197, 'Híbrido', 9.8, 89.0, '0W-16 Sintético', 'assets/carros/suzuki/swift.png', 96),
    ('suzuki', 'carro', 'Vitara', 'Vitara Live AllGrip', 2017, 1586, 'Gasolina', 12.4, 115.0, '5W-30 Sintético', 'assets/carros/suzuki/vitara.png', 93),
    ('suzuki', 'carro', 'Jimny', 'Jimny GLX 1.5 4x4', 2019, 1462, 'Gasolina', 10.5, 100.0, '0W-20 Sintético', 'assets/carros/suzuki/jimny.png', 94),

    -- VOLKSWAGEN (CARROS)
    ('volkswagen', 'carro', 'Gol', 'Gol Trendline 1.6', 2014, 1598, 'Gasolina', 14.5, 101.0, '5W-40 Sintético', 'assets/carros/volkswagen/gol.png', 94),
    ('volkswagen', 'carro', 'T-Cross', 'T-Cross 1.0 TSI Turbo', 2021, 999, 'Gasolina', 13.2, 114.0, '5W-40 Sintético', 'assets/carros/volkswagen/tcross.png', 95),
    ('volkswagen', 'carro', 'Amarok', 'Amarok V6 Highline 4x4', 2018, 2967, 'Diésel', 21.1, 258.0, '5W-30 Diésel', 'assets/carros/volkswagen/amarok.png', 91),

    -- FORD (CARROS)
    ('ford', 'carro', 'Ranger', 'Ranger XLT / Limited 4x4', 2016, 3198, 'Diésel', 21.1, 197.0, '5W-30 Diésel', 'assets/carros/ford/ranger.png', 95),
    ('ford', 'carro', 'Escape', 'Escape Titanium Híbrida', 2020, 2488, 'Híbrido', 14.3, 200.0, '0W-20 Sintético', 'assets/carros/ford/escape.png', 94),
    ('ford', 'carro', 'Explorer', 'Explorer Limited 2.3 EcoBoost', 2018, 2296, 'Gasolina', 19.3, 300.0, '5W-30 Sintético', 'assets/carros/ford/explorer.png', 90),

    -- HYUNDAI (CARROS)
    ('hyundai', 'carro', 'Grand i10', 'Grand i10 HB20 1.25 / 1.6', 2016, 1591, 'Gasolina', 11.3, 121.0, '5W-30 Sintético', 'assets/carros/hyundai/hb20.png', 93),
    ('hyundai', 'carro', 'Tucson', 'Tucson Limited 2.0', 2018, 1999, 'Gasolina', 14.3, 154.0, '5W-30 Sintético', 'assets/carros/hyundai/tucson.png', 92),

    -- BYD (ELÉCTRICOS / HÍBRIDOS)
    ('byd', 'carro', 'Dolphin', 'Dolphin Mini 100% EV', 2024, 0, 'Eléctrico', 0.0, 75.0, 'No Requiere', 'assets/carros/byd/dolphin_mini.png', 96),
    ('byd', 'carro', 'Song Plus', 'Song Plus DM-i Híbrido Enchufable', 2022, 1498, 'Híbrido', 15.8, 214.0, '0W-20 Sintético', 'assets/carros/byd/song_plus.png', 94)
ON CONFLICT DO NOTHING;
