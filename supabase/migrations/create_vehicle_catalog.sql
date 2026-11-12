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
    ('bajaj', 'Bajaj', 'moto', 'assets/logos/bajaj_logo.png', '#0047BA', 'India', 100),
    ('yamaha', 'Yamaha', 'moto', 'assets/logos/yamaha_logo.png', '#D31145', 'Japón', 99),
    ('akt', 'AKT Motos', 'moto', 'assets/logos/akt_logo.png', '#E31E24', 'Colombia', 98),
    ('suzuki', 'Suzuki', 'ambos', 'assets/logos/suzuki_logo.png', '#E30613', 'Japón', 96),
    ('honda', 'Honda', 'ambos', 'assets/logos/honda_logo.png', '#CC0000', 'Japón', 95),
    ('tvs', 'TVS', 'moto', 'assets/logos/tvs_logo.png', '#002B49', 'India', 94),
    ('hero', 'Hero MotoCorp', 'moto', 'assets/logos/hero_logo.png', '#ED1C24', 'India', 92),
    ('ktm', 'KTM', 'moto', 'assets/logos/ktm_logo.png', '#FF6600', 'Austria', 90),
    ('victory', 'Victory', 'moto', 'assets/logos/victori_logo.png', '#FFCC00', 'Colombia', 88),
    ('bmw', 'BMW', 'ambos', 'assets/logos/bmw_logo.png', '#0066B1', 'Alemania', 85),

    -- Carros
    ('renault', 'Renault', 'carro', 'assets/logos/renault_logo.png', '#FFCC00', 'Francia', 100),
    ('chevrolet', 'Chevrolet', 'carro', 'assets/logos/chevrolet_logo.png', '#CD9834', 'Estados Unidos', 99),
    ('toyota', 'Toyota', 'carro', 'assets/logos/toyota_logo.png', '#EB0A1E', 'Japón', 98),
    ('mazda', 'Mazda', 'carro', 'assets/logos/mazda_logo.png', '#1B365D', 'Japón', 97),
    ('kia', 'Kia', 'carro', 'assets/logos/kia_logo.png', '#05141F', 'Corea del Sur', 96),
    ('nissan', 'Nissan', 'carro', 'assets/logos/nissan_logo.png', '#C3002F', 'Japón', 90),
    ('volkswagen', 'Volkswagen', 'carro', 'assets/logos/volkswagen_logo.png', '#001E50', 'Alemania', 88),
    ('ford', 'Ford', 'carro', 'assets/logos/ford_logo.png', '#003478', 'Estados Unidos', 86),
    ('hyundai', 'Hyundai', 'carro', 'assets/logos/hyundai_logo.png', '#002C6C', 'Corea del Sur', 85),
    ('byd', 'BYD', 'carro', 'assets/logos/byd_logo.png', '#E60012', 'China', 84)
ON CONFLICT (id) DO UPDATE SET
    nombre = EXCLUDED.nombre,
    tipo = EXCLUDED.tipo,
    color_hex = EXCLUDED.color_hex,
    popularidad = EXCLUDED.popularidad;

-- 8. SEED INICIAL: TOP MODELOS COLOMBIA CON ESPECIFICACIONES TÉCNICAS REALES
INSERT INTO public.catalogo_modelos 
(marca_id, tipo, linea, modelo, anio_inicio, cilindraje_cc, tipo_combustible, capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad)
VALUES
    -- MOTOS LÍDERES COLOMBIA
    ('akt', 'moto', 'NKD', 'NKD 125', 2012, 124, 'Gasolina', 2.60, 10.3, '20W-50 4T Mineral', 'assets/motos/akt/NKD.png', 100),
    ('akt', 'moto', 'CR4', 'CR4 150', 2018, 149, 'Gasolina', 3.10, 12.0, '20W-50 4T Semisintético', 'assets/motos/akt/CR4_150.png', 90),
    ('akt', 'moto', 'Dynamic', 'Dynamic Pro 125', 2017, 124, 'Gasolina', 1.30, 8.9, '10W-40 4T Scooter', 'assets/motos/akt/dinamicpro.png', 85),
    
    ('bajaj', 'moto', 'Boxer', 'Boxer CT 100', 2012, 102, 'Gasolina', 2.80, 7.6, '20W-50 4T Mineral', 'assets/motos/bajaj/boxer-ct100.png', 99),
    ('bajaj', 'moto', 'Pulsar', 'Pulsar NS 200 FI ABS', 2018, 200, 'Gasolina', 3.17, 24.1, '20W-50 4T Sintético', 'assets/motos/bajaj/pulsar-ns200-fi-abs.png', 98),
    ('bajaj', 'moto', 'Pulsar', 'Pulsar N160', 2023, 165, 'Gasolina', 3.70, 15.7, '20W-50 4T Semisintético', 'assets/motos/bajaj/pulsar-n160.png', 94),
    ('bajaj', 'moto', 'Pulsar', 'Pulsar N250', 2022, 249, 'Gasolina', 3.70, 24.5, '20W-50 4T Semisintético', 'assets/motos/bajaj/Pulsar-N250.png', 92),
    ('bajaj', 'moto', 'Dominar', 'Dominar 400 Touring', 2019, 373, 'Gasolina', 3.43, 39.5, '10W-50 4T Sintético', 'assets/motos/bajaj/Dominar-400-touring.png', 91),

    ('yamaha', 'moto', 'N-Max', 'N-MAX Connected 155', 2016, 155, 'Gasolina', 1.87, 15.1, '10W-40 Yamalube AT Scooter', 'assets/motos/yamaha/nmax.png', 99),
    ('yamaha', 'moto', 'Crypton', 'Crypton FI 115', 2014, 114, 'Gasolina', 1.08, 8.6, '20W-50 Yamalube 4T Mineral', 'assets/motos/yamaha/cripton.png', 96),
    ('yamaha', 'moto', 'FZ', 'FZ 25', 2018, 249, 'Gasolina', 3.70, 20.6, '10W-40 Yamalube Semisintético', 'assets/motos/yamaha/fz25.png', 95),
    ('yamaha', 'moto', 'XTZ', 'XTZ 150', 2019, 149, 'Gasolina', 3.17, 12.3, '20W-50 Yamalube 4T', 'assets/motos/yamaha/XTZ150.png', 93),
    ('yamaha', 'moto', 'MT', 'MT 15', 2020, 155, 'Gasolina', 2.64, 19.0, '10W-40 Yamalube Sintético', 'assets/motos/yamaha/mt15.png', 94),

    ('suzuki', 'moto', 'Gixxer', 'Gixxer 150 FI', 2016, 155, 'Gasolina', 3.17, 13.6, '10W-40 ECSTAR Semisintético', 'assets/motos/suzuki/gixxer150.png', 97),
    ('suzuki', 'moto', 'GN', 'GN 125', 2012, 124, 'Gasolina', 2.72, 12.5, '20W-50 4T Mineral', 'assets/motos/suzuki/GN125.png', 95),
    ('suzuki', 'moto', 'DR', 'DR 150', 2019, 149, 'Gasolina', 3.30, 12.2, '10W-40 ECSTAR Semisintético', 'assets/motos/suzuki/DR.png', 93),

    ('tvs', 'moto', 'Raider', 'Raider 125', 2022, 125, 'Gasolina', 2.64, 12.7, '10W-30 TVS TRU4 Sintético', 'assets/motos/tvs/raider125.png', 95),
    ('tvs', 'moto', 'Apache', 'Apache RTR 160 4V', 2019, 160, 'Gasolina', 3.17, 17.3, '10W-30 TVS TRU4 Sintético', 'assets/motos/tvs/apache160.png', 93),

    ('honda', 'moto', 'CB', 'CB 125F', 2016, 124, 'Gasolina', 2.90, 10.6, '10W-30 Honda 4T Semisintético', 'assets/motos/honda/cb125f.png', 94),
    ('honda', 'moto', 'CB', 'CB 160F', 2018, 163, 'Gasolina', 3.17, 13.0, '10W-30 Honda 4T Semisintético', 'assets/motos/honda/cb160f.png', 90),

    ('hero', 'moto', 'Eco', 'Eco Deluxe', 2014, 97, 'Gasolina', 2.50, 8.2, '10W-30 Hero 4T Plus', 'assets/motos/hero/Eco_Deluxe.png', 92),
    ('hero', 'moto', 'Splendor', 'Splendor Xpro', 2016, 109, 'Gasolina', 2.37, 9.3, '10W-30 Hero 4T Plus', 'assets/motos/hero/Splendor-Xpro.png', 89),
    ('hero', 'moto', 'XPulse', 'XPulse 200 4V', 2021, 200, 'Gasolina', 3.43, 19.1, '10W-30 Hero 4T Sintético', 'assets/motos/hero/Xpulse2004v.png', 91),

    ('ktm', 'moto', 'Duke', 'Duke 200 NG', 2020, 200, 'Gasolina', 3.54, 25.0, '15W-50 Motorex Sintético', 'assets/motos/ktm/DUKE-200.png', 92),
    ('ktm', 'moto', 'Duke', 'Duke 390', 2018, 373, 'Gasolina', 3.54, 43.5, '15W-50 Motorex Sintético', 'assets/motos/ktm/KTM-390-DUKE.png', 90),

    -- CARROS LÍDERES COLOMBIA
    ('renault', 'carro', 'Duster', 'Duster 1.6 / 1.3T', 2014, 1598, 'Gasolina', 13.2, 114.0, '10W-40 Semisintético ELF', 'assets/carros/renault/duster.png', 100),
    ('renault', 'carro', 'Sandero', 'Sandero / Stepway 1.6', 2012, 1598, 'Gasolina', 13.2, 111.0, '10W-40 Semisintético ELF', 'assets/carros/renault/sandero.png', 97),
    ('renault', 'carro', 'Kwid', 'Kwid 1.0 Zen/Outsider', 2019, 999, 'Gasolina', 9.2, 66.0, '10W-40 Sintético ELF', 'assets/carros/renault/kwid.png', 96),

    ('chevrolet', 'carro', 'Onix', 'Onix Turbo Sedán', 2020, 999, 'Gasolina', 11.6, 115.0, '5W-30 Sintético Dexos1 Gen3', 'assets/carros/chevrolet/onix-turbo-sedan.png', 100),
    ('chevrolet', 'carro', 'Tracker', 'Tracker Turbo RS', 2021, 1199, 'Gasolina', 11.6, 132.0, '5W-30 Sintético Dexos1 Gen3', 'assets/carros/chevrolet/tracker-RS.png', 98),
    ('chevrolet', 'carro', 'Spark', 'Spark GT / Beat', 2012, 1206, 'Gasolina', 9.2, 80.5, '5W-30 Semisintético ACDelco', 'assets/carros/chevrolet/SparkEUV.png', 96),
    ('chevrolet', 'carro', 'Captiva', 'Captiva Turbo XL', 2020, 1451, 'Gasolina', 13.7, 144.0, '5W-30 Sintético Dexos1', 'assets/carros/chevrolet/CAPTIVA_TURBO-XL.png', 93),

    ('kia', 'carro', 'Picanto', 'Picanto Emotion / GT-Line', 2018, 1248, 'Gasolina', 9.2, 83.0, '5W-30 Sintético Total Quartz', 'assets/carros/kia/picanto.png', 100),

    ('mazda', 'carro', 'Mazda 2', 'Mazda 2 Sport Hatchback', 2016, 1496, 'Gasolina', 11.6, 108.0, '0W-20 Sintético Mazda Original', 'assets/carros/mazda/mazda2.png', 98),
    ('mazda', 'carro', 'Mazda 2', 'Mazda 2 Sedán', 2017, 1496, 'Gasolina', 11.6, 108.0, '0W-20 Sintético Mazda Original', 'assets/carros/mazda/mazda2sedan.png', 96),
    ('mazda', 'carro', 'Mazda 3', 'Mazda 3 Sedán / Sport', 2019, 1998, 'Gasolina', 13.4, 153.0, '0W-20 Sintético Mazda Original', 'assets/carros/mazda/mazda3.png', 95),

    ('toyota', 'carro', 'Corolla Cross', 'Corolla Cross Híbrido XEI', 2021, 1798, 'Híbrido', 9.5, 126.0, '0W-20 Sintético Toyota Genuine', 'assets/carros/toyota/corolla_cross.png', 100),
    ('toyota', 'carro', 'Hilux', 'Hilux 2.4 / 2.8 Diésel 4x4', 2016, 2755, 'Diésel', 21.1, 201.0, '5W-30 Sintético Toyota DL-1', 'assets/carros/toyota/hilux.png', 99),
    ('toyota', 'carro', 'Fortuner', 'Fortuner SW4 2.8 Diésel', 2017, 2755, 'Diésel', 21.1, 201.0, '5W-30 Sintético Toyota Genuine', 'assets/carros/toyota/fortuner.png', 96),
    ('toyota', 'carro', 'Corolla', 'Corolla Sedán Híbrido SEG', 2020, 1798, 'Híbrido', 11.3, 126.0, '0W-20 Sintético Toyota Genuine', 'assets/carros/toyota/corolla.png', 94),
    ('toyota', 'carro', 'Yaris', 'Yaris Sedán / HB', 2021, 1496, 'Gasolina', 11.1, 105.0, '0W-20 Sintético Toyota Genuine', 'assets/carros/toyota/yaris.png', 93),
    ('toyota', 'carro', 'Prado', 'Land Cruiser Prado TXL 300', 2015, 2755, 'Diésel', 23.0, 201.0, '5W-30 Sintético Toyota Genuine', 'assets/carros/toyota/landcruiser300.png', 98)
ON CONFLICT DO NOTHING;
