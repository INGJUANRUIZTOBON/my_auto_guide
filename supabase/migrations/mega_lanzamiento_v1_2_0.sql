-- =============================================================================
-- mega_lanzamiento_v1_2_0.sql — MEGA LANZAMIENTO COLOMBIA v1.2.0+17
-- =============================================================================
-- Ejecutar en Supabase Dashboard -> SQL Editor.

-- 1. Columnas adicionales en vehiculos (RUNT + Documentos Colombia + Modo Conductor)
ALTER TABLE public.vehiculos
    ADD COLUMN IF NOT EXISTS runt_data JSONB DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS runt_last_check TIMESTAMPTZ DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS licencia_vencimiento TEXT DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS impuesto_vencimiento TEXT DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS extintor_vencimiento TEXT DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS modo_conductor BOOLEAN DEFAULT FALSE;

-- 2. Mantenimientos personalizados por vehiculo (Llantas, Frenos, Bateria, etc.)
CREATE TABLE IF NOT EXISTS public.custom_maintenances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    vehiculo_id UUID NOT NULL REFERENCES public.vehiculos(id) ON DELETE CASCADE,
    nombre TEXT NOT NULL,
    ciclo_dias INTEGER NOT NULL DEFAULT 180,
    ciclo_kms INTEGER NOT NULL DEFAULT 10000,
    ultima_fecha TIMESTAMPTZ DEFAULT timezone('utc'::text, now()),
    ultimo_km NUMERIC DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.custom_maintenances ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "CRUD custom_maintenances propio" ON public.custom_maintenances;
CREATE POLICY "CRUD custom_maintenances propio"
    ON public.custom_maintenances FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 3. Ingresos de conductor / rentabilidad (Uber, DiDi, InDrive, Rappi, Fletes)
CREATE TABLE IF NOT EXISTS public.driver_incomes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    vehiculo_id UUID NOT NULL REFERENCES public.vehiculos(id) ON DELETE CASCADE,
    plataforma TEXT NOT NULL,
    monto_bruto NUMERIC NOT NULL DEFAULT 0,
    peajes NUMERIC NOT NULL DEFAULT 0,
    otros_gastos NUMERIC NOT NULL DEFAULT 0,
    kms_turno NUMERIC NOT NULL DEFAULT 0,
    notas TEXT DEFAULT '',
    fecha TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.driver_incomes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "CRUD driver_incomes propio" ON public.driver_incomes;
CREATE POLICY "CRUD driver_incomes propio"
    ON public.driver_incomes FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 4. Mapa comunitario de precios de combustible en Colombia
CREATE TABLE IF NOT EXISTS public.fuel_station_prices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    ciudad TEXT NOT NULL DEFAULT 'Colombia',
    estacion TEXT NOT NULL,
    tipo_combustible TEXT NOT NULL DEFAULT 'Corriente',
    precio_galon NUMERIC NOT NULL,
    latitud DOUBLE PRECISION DEFAULT 0,
    longitud DOUBLE PRECISION DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.fuel_station_prices ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Lectura publica precios gasolina" ON public.fuel_station_prices;
CREATE POLICY "Lectura publica precios gasolina"
    ON public.fuel_station_prices FOR SELECT
    TO public, anon, authenticated
    USING (true);
DROP POLICY IF EXISTS "Insertar precio gasolina autenticado" ON public.fuel_station_prices;
CREATE POLICY "Insertar precio gasolina autenticado"
    ON public.fuel_station_prices FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- 5. Modulo de Flotas y Preoperacional PESV Colombia
CREATE TABLE IF NOT EXISTS public.flotas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    nombre TEXT NOT NULL,
    codigo_invitacion TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.flota_miembros (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    flota_id UUID NOT NULL REFERENCES public.flotas(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    vehiculo_id UUID REFERENCES public.vehiculos(id) ON DELETE SET NULL,
    rol TEXT NOT NULL DEFAULT 'conductor',
    alias_conductor TEXT DEFAULT 'Conductor',
    placa_snapshot TEXT DEFAULT '',
    marca_modelo_snapshot TEXT DEFAULT '',
    soat_vencimiento TEXT DEFAULT NULL,
    tecno_vencimiento TEXT DEFAULT NULL,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(flota_id, user_id, vehiculo_id)
);

CREATE TABLE IF NOT EXISTS public.inspecciones_preoperacionales (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    flota_id UUID REFERENCES public.flotas(id) ON DELETE SET NULL,
    vehiculo_id UUID NOT NULL REFERENCES public.vehiculos(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    aprobada BOOLEAN NOT NULL DEFAULT TRUE,
    items_json JSONB NOT NULL DEFAULT '{}'::jsonb,
    observaciones TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.flotas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.flota_miembros ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inspecciones_preoperacionales ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Lectura flotas para autenticados" ON public.flotas;
CREATE POLICY "Lectura flotas para autenticados"
    ON public.flotas FOR SELECT
    TO authenticated
    USING (true);
DROP POLICY IF EXISTS "Gestion flota por dueno" ON public.flotas;
CREATE POLICY "Gestion flota por dueno"
    ON public.flotas FOR ALL
    TO authenticated
    USING (auth.uid() = owner_id)
    WITH CHECK (auth.uid() = owner_id);

DROP POLICY IF EXISTS "Ver miembros de flota" ON public.flota_miembros;
CREATE POLICY "Ver miembros de flota"
    ON public.flota_miembros FOR SELECT
    TO authenticated
    USING (
        auth.uid() = user_id
        OR EXISTS (SELECT 1 FROM public.flotas f WHERE f.id = flota_id AND f.owner_id = auth.uid())
    );
DROP POLICY IF EXISTS "Insertar membresia propia" ON public.flota_miembros;
CREATE POLICY "Insertar membresia propia"
    ON public.flota_miembros FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Eliminar membresia propia o dueno" ON public.flota_miembros;
CREATE POLICY "Eliminar membresia propia o dueno"
    ON public.flota_miembros FOR DELETE
    TO authenticated
    USING (
        auth.uid() = user_id
        OR EXISTS (SELECT 1 FROM public.flotas f WHERE f.id = flota_id AND f.owner_id = auth.uid())
    );

DROP POLICY IF EXISTS "Ver preoperacionales propios o flota" ON public.inspecciones_preoperacionales;
CREATE POLICY "Ver preoperacionales propios o flota"
    ON public.inspecciones_preoperacionales FOR SELECT
    TO authenticated
    USING (
        auth.uid() = user_id
        OR EXISTS (SELECT 1 FROM public.flotas f WHERE f.id = flota_id AND f.owner_id = auth.uid())
    );
DROP POLICY IF EXISTS "Crear preoperacional propio" ON public.inspecciones_preoperacionales;
CREATE POLICY "Crear preoperacional propio"
    ON public.inspecciones_preoperacionales FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- 6. Publicacion OTA v1.2.0+17
INSERT INTO public.app_versions (
    version_code,
    version_name,
    zip_url,
    release_notes,
    is_mandatory,
    min_supported_version
)
VALUES (
    17,
    '1.2.0',
    'https://github.com/INGJUANRUIZTOBON/my_auto_guide/releases/download/1.1.0/app-release.apk',
    '• Pico y Placa automático por GPS en Colombia (notificaciones noche y mañana).\n• Mantenimientos diferenciados Carro vs Moto + mantenimientos personalizados.\n• Documentos extra: Licencia, Impuesto vehicular y Extintor/Kit.\n• Navegación Pro Colombia: Peajes estimados, precios de gasolina, alertas Moto y voz manos libres.\n• OBD2 Pro: Modo HUD parabrisas, Freeze Frame y gráficas en vivo.\n• Modo Conductor (rentabilidad neta/km) + Mi Flota con Preoperacional PESV.\n• Hoja de Vida PDF Certificada transferible.',
    true,
    1
)
ON CONFLICT (version_code) DO UPDATE
SET
    version_name = EXCLUDED.version_name,
    zip_url = EXCLUDED.zip_url,
    release_notes = EXCLUDED.release_notes,
    is_mandatory = EXCLUDED.is_mandatory,
    min_supported_version = EXCLUDED.min_supported_version;
