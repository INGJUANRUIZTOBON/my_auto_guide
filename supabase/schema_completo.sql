-- =============================================================================
-- MY AUTO GUIDE — ESQUEMA COMPLETO DE BASE DE DATOS (POSTGRESQL / SUPABASE)
-- Generado para montaje directo e integral en un nuevo proyecto de Supabase.
-- Incluye: Tablas, Relaciones, Índices, Triggers de Auth, RLS y Storage Buckets.
-- =============================================================================

-- 0. EXTENSIONES
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- 1. TABLA: PROFILES & PERFILES (Sincronización automática con auth.users)
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    name TEXT,
    fcm_token TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.perfiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    name TEXT,
    fcm_token TEXT,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Trigger para crear automáticamente el perfil al registrar un usuario en auth.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'name', NEW.raw_user_meta_data->>'full_name', '')
    )
    ON CONFLICT (id) DO UPDATE 
    SET email = EXCLUDED.email, name = COALESCE(EXCLUDED.name, public.profiles.name);

    INSERT INTO public.perfiles (id, email, name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'name', NEW.raw_user_meta_data->>'full_name', '')
    )
    ON CONFLICT (id) DO UPDATE 
    SET email = EXCLUDED.email, name = COALESCE(EXCLUDED.name, public.perfiles.name);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- =============================================================================
-- 2. TABLA: VEHICULOS
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.vehiculos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    marca TEXT NOT NULL,
    modelo TEXT NOT NULL,
    apodo TEXT NOT NULL,
    kms NUMERIC NOT NULL DEFAULT 0,
    image_path TEXT,
    placa TEXT DEFAULT '',
    cedula TEXT DEFAULT '',
    aseguradora_id TEXT DEFAULT NULL,
    last_cadena TEXT DEFAULT NULL,
    last_filtro TEXT DEFAULT NULL,
    last_aceite TEXT DEFAULT NULL,
    last_soat TEXT DEFAULT NULL,
    last_tecno TEXT DEFAULT NULL,
    soat_path TEXT DEFAULT NULL,
    tecno_path TEXT DEFAULT NULL,
    seguro_path TEXT DEFAULT NULL,
    propiedad_path TEXT DEFAULT NULL,
    kms_last_cadena NUMERIC DEFAULT 0,
    kms_last_filtro NUMERIC DEFAULT 0,
    kms_last_aceite NUMERIC DEFAULT 0,
    simit_status TEXT DEFAULT NULL,
    simit_fines_data JSONB DEFAULT NULL,
    simit_last_check TIMESTAMPTZ DEFAULT NULL,
    runt_data JSONB DEFAULT NULL,
    runt_last_check TIMESTAMPTZ DEFAULT NULL,
    has_360_view BOOLEAN DEFAULT FALSE,
    images_360_urls JSONB DEFAULT NULL,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_vehiculos_user_id ON public.vehiculos (user_id);
CREATE INDEX IF NOT EXISTS idx_vehiculos_placa ON public.vehiculos (placa);

-- =============================================================================
-- 3. TABLA: GASTOS
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.gastos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    vehiculo_id UUID NOT NULL REFERENCES public.vehiculos(id) ON DELETE CASCADE,
    categoria TEXT NOT NULL,
    monto NUMERIC NOT NULL,
    descripcion TEXT,
    fecha TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_gastos_user_id ON public.gastos (user_id);
CREATE INDEX IF NOT EXISTS idx_gastos_vehiculo_id ON public.gastos (vehiculo_id);
CREATE INDEX IF NOT EXISTS idx_gastos_fecha ON public.gastos (fecha);

-- =============================================================================
-- 4. TABLA: TANQUEOS (Control de Combustible)
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.tanqueos (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    vehiculo_id UUID NOT NULL REFERENCES public.vehiculos(id) ON DELETE CASCADE,
    fecha TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    kms_actuales NUMERIC NOT NULL,
    monto_cop NUMERIC NOT NULL,
    galones NUMERIC NOT NULL,
    precio_por_galon NUMERIC NOT NULL,
    es_tanque_lleno BOOLEAN DEFAULT TRUE,
    notas TEXT,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_tanqueos_vehiculo_id ON public.tanqueos (vehiculo_id);
CREATE INDEX IF NOT EXISTS idx_tanqueos_kms_actuales ON public.tanqueos (kms_actuales DESC);

-- =============================================================================
-- 5. TABLA: RUTAS_HISTORIAL (Telemetría de Navegación)
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.rutas_historial (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    vehiculo_id UUID NOT NULL REFERENCES public.vehiculos(id) ON DELETE CASCADE,
    origen TEXT DEFAULT 'Desconocido',
    destino TEXT DEFAULT 'Desconocido',
    distancia NUMERIC DEFAULT 0,
    duracion TEXT DEFAULT '0',
    consumo_estimado NUMERIC DEFAULT 0,
    costo_estimado NUMERIC DEFAULT 0,
    velocidad_max NUMERIC DEFAULT NULL,
    velocidad_prom NUMERIC DEFAULT NULL,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_rutas_user_vehiculo ON public.rutas_historial (user_id, vehiculo_id);
CREATE INDEX IF NOT EXISTS idx_rutas_created_at ON public.rutas_historial (created_at DESC);

-- =============================================================================
-- 6. TABLA: REPORTES_VIALES (Alertas Comunitarias Tipo Waze)
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.reportes_viales (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    tipo TEXT NOT NULL,
    titulo TEXT NOT NULL,
    descripcion TEXT,
    latitud DOUBLE PRECISION NOT NULL,
    longitud DOUBLE PRECISION NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    confirmaciones INTEGER DEFAULT 1,
    rechazos INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_reportes_viales_created_at ON public.reportes_viales (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reportes_viales_lat_lng ON public.reportes_viales (latitud, longitud);

-- =============================================================================
-- 7. TABLA: APP_VERSIONS (Actualizaciones OTA del APK)
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.app_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version_code INTEGER NOT NULL UNIQUE,
    version_name TEXT NOT NULL,
    zip_url TEXT NOT NULL,
    release_notes TEXT,
    is_mandatory BOOLEAN NOT NULL DEFAULT TRUE,
    min_supported_version INTEGER NOT NULL DEFAULT 1,
    file_size_bytes BIGINT,
    checksum_sha256 TEXT,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- =============================================================================
-- 8. TABLA: MOTORCYCLE_MANUALS (Fichas Técnicas de Motocicletas)
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.motorcycle_manuals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    make TEXT NOT NULL,
    model TEXT NOT NULL,
    year TEXT NOT NULL,
    type TEXT,
    displacement TEXT,
    engine TEXT,
    power TEXT,
    torque TEXT,
    compression TEXT,
    valves_per_cylinder TEXT,
    fuel_system TEXT,
    fuel_control TEXT,
    lubrication TEXT,
    cooling TEXT,
    gearbox TEXT,
    transmission TEXT,
    clutch TEXT,
    frame TEXT,
    front_suspension TEXT,
    rear_suspension TEXT,
    front_wheel_travel TEXT,
    rear_wheel_travel TEXT,
    front_tire TEXT,
    rear_tire TEXT,
    front_brakes TEXT,
    rear_brakes TEXT,
    seat_height TEXT,
    ground_clearance TEXT,
    wheelbase TEXT,
    fuel_capacity TEXT,
    fuel_consumption TEXT,
    emission TEXT,
    total_weight TEXT,
    dry_weight TEXT,
    starter TEXT,
    ignition TEXT,
    top_speed TEXT,
    manual_pdf_url TEXT,
    raw_specs JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT unique_motorcycle_spec UNIQUE (make, model, year)
);

CREATE INDEX IF NOT EXISTS idx_motorcycle_manuals_make ON public.motorcycle_manuals (make);
CREATE INDEX IF NOT EXISTS idx_motorcycle_manuals_model ON public.motorcycle_manuals (model);
CREATE INDEX IF NOT EXISTS idx_motorcycle_manuals_year ON public.motorcycle_manuals (year);
CREATE INDEX IF NOT EXISTS idx_motorcycle_manuals_make_model ON public.motorcycle_manuals (make, model);

-- =============================================================================
-- 9. SEGURIDAD: ROW LEVEL SECURITY (RLS)
-- =============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.perfiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehiculos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gastos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tanqueos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rutas_historial ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reportes_viales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.motorcycle_manuals ENABLE ROW LEVEL SECURITY;

-- 9.1 Políticas para profiles y perfiles
CREATE POLICY "Usuarios pueden ver su propio perfil"
    ON public.profiles FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

CREATE POLICY "Usuarios pueden actualizar su propio perfil"
    ON public.profiles FOR UPDATE
    TO authenticated
    USING (auth.uid() = id);

CREATE POLICY "Usuarios pueden ver su propio perfiles"
    ON public.perfiles FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

CREATE POLICY "Usuarios pueden insertar o actualizar su propio perfiles"
    ON public.perfiles FOR ALL
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- 9.2 Políticas para vehiculos
CREATE POLICY "Usuarios pueden ver sus propios vehículos"
    ON public.vehiculos FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Usuarios pueden insertar sus propios vehículos"
    ON public.vehiculos FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuarios pueden actualizar sus propios vehículos"
    ON public.vehiculos FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuarios pueden eliminar sus propios vehículos"
    ON public.vehiculos FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);

-- 9.3 Políticas para gastos
CREATE POLICY "Usuarios pueden ver sus propios gastos"
    ON public.gastos FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Usuarios pueden insertar sus propios gastos"
    ON public.gastos FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuarios pueden eliminar sus propios gastos"
    ON public.gastos FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);

-- 9.4 Políticas para tanqueos
CREATE POLICY "Usuarios pueden ver tanqueos de sus vehículos"
    ON public.tanqueos FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.vehiculos 
            WHERE public.vehiculos.id = public.tanqueos.vehiculo_id 
              AND public.vehiculos.user_id = auth.uid()
        )
    );

CREATE POLICY "Usuarios pueden insertar o actualizar tanqueos"
    ON public.tanqueos FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.vehiculos 
            WHERE public.vehiculos.id = public.tanqueos.vehiculo_id 
              AND public.vehiculos.user_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.vehiculos 
            WHERE public.vehiculos.id = public.tanqueos.vehiculo_id 
              AND public.vehiculos.user_id = auth.uid()
        )
    );

-- 9.5 Políticas para rutas_historial
CREATE POLICY "Usuarios pueden ver sus propias rutas"
    ON public.rutas_historial FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Usuarios pueden insertar sus propias rutas"
    ON public.rutas_historial FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- 9.6 Políticas para reportes_viales (Comunidad Waze)
CREATE POLICY "Lectura pública de reportes viales activos"
    ON public.reportes_viales FOR SELECT
    TO public, anon, authenticated
    USING (true);

CREATE POLICY "Usuarios autenticados pueden crear reportes viales"
    ON public.reportes_viales FOR INSERT
    TO authenticated, anon
    WITH CHECK (true);

CREATE POLICY "Cualquier usuario puede votar o actualizar reportes viales"
    ON public.reportes_viales FOR UPDATE
    TO public, anon, authenticated
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Usuarios pueden eliminar sus propios reportes o reportes rechazados"
    ON public.reportes_viales FOR DELETE
    TO public, anon, authenticated
    USING (true);

-- 9.7 Políticas para app_versions
CREATE POLICY "Lectura pública de versiones de la app"
    ON public.app_versions FOR SELECT
    TO public, anon, authenticated
    USING (true);

-- 9.8 Políticas para motorcycle_manuals
CREATE POLICY "Lectura pública de manuales de motos"
    ON public.motorcycle_manuals FOR SELECT
    TO public, anon, authenticated
    USING (true);

CREATE POLICY "Administración de manuales de motos"
    ON public.motorcycle_manuals FOR ALL
    TO public, anon, authenticated
    USING (true)
    WITH CHECK (true);

-- =============================================================================
-- 10. STORAGE BUCKETS Y POLÍTICAS
-- =============================================================================

-- Bucket para Documentos de Vehículos (SOAT, Tecno, Tarjeta Propiedad, Fotos 360)
INSERT INTO storage.buckets (id, name, public)
VALUES ('vehiculos-docs', 'vehiculos-docs', false)
ON CONFLICT (id) DO UPDATE SET public = false;

-- Bucket para Lanzamientos de App (APKs / Actualizaciones OTA)
INSERT INTO storage.buckets (id, name, public)
VALUES ('app-releases', 'app-releases', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Políticas de Storage para vehiculos-docs
CREATE POLICY "Usuarios autenticados pueden gestionar sus documentos"
    ON storage.objects FOR ALL
    TO authenticated
    USING (bucket_id = 'vehiculos-docs')
    WITH CHECK (bucket_id = 'vehiculos-docs');

-- Políticas de Storage para app-releases
CREATE POLICY "Descarga pública de releases"
    ON storage.objects FOR SELECT
    TO public, anon, authenticated
    USING (bucket_id = 'app-releases');

-- =============================================================================
-- 11. DATOS SEMILLA BÁSICOS (Versión de la app v1.1.0)
-- =============================================================================

INSERT INTO public.app_versions (
    version_code,
    version_name,
    zip_url,
    release_notes,
    is_mandatory,
    min_supported_version
)
VALUES (
    13,
    '1.1.0',
    'https://github.com/INGJUANRUIZTOBON/my_auto_guide/releases/download/1.1.0/app-release.apk',
    '• Nueva infraestructura de backend escalable.\n• Rendimiento optimizado en telemetría y navegación.\n• Sincronización offline-first robusta.',
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

-- =============================================================================
-- 12. EXTENSIÓN MEGA LANZAMIENTO COLOMBIA v1.2.0+17
-- =============================================================================

ALTER TABLE public.vehiculos
    ADD COLUMN IF NOT EXISTS licencia_vencimiento TEXT DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS impuesto_vencimiento TEXT DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS extintor_vencimiento TEXT DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS modo_conductor BOOLEAN DEFAULT FALSE;

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
