-- =============================================================================
-- 20261113_fix_runt_and_driver_license_sync.sql
-- Sincronización Cloud Completa: Ficha RUNT del Vehículo y Mi Licencia RUNT
-- Protegido con Row Level Security (RLS) estricto (Aislamiento por Usuario)
-- =============================================================================

-- 1. Columnas para Ficha Técnica RUNT y Licencia en tabla public.vehiculos
ALTER TABLE public.vehiculos
    ADD COLUMN IF NOT EXISTS runt_data JSONB DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS runt_last_check TIMESTAMPTZ DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS driver_license_data JSONB DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS licencia_vencimiento TEXT DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS impuesto_vencimiento TEXT DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS extintor_vencimiento TEXT DEFAULT NULL;

-- 2. Columnas para Licencia a nivel de Usuario Conductor en public.profiles
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS driver_license_data JSONB DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS cedula TEXT DEFAULT NULL;

-- 3. Columnas en public.perfiles (compatibilidad retroactiva)
ALTER TABLE public.perfiles
    ADD COLUMN IF NOT EXISTS driver_license_data JSONB DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS cedula TEXT DEFAULT NULL;

-- 4. Verificación de Row Level Security (RLS)
-- Asegura que NINGÚN usuario ajeno pueda ver ni modificar los datos de otro.
ALTER TABLE public.vehiculos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.perfiles ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    -- Políticas para public.vehiculos
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'vehiculos' AND policyname = 'Usuarios pueden ver sus propios vehículos'
    ) THEN
        CREATE POLICY "Usuarios pueden ver sus propios vehículos"
            ON public.vehiculos FOR SELECT
            TO authenticated
            USING (auth.uid() = user_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'vehiculos' AND policyname = 'Usuarios pueden actualizar sus propios vehículos'
    ) THEN
        CREATE POLICY "Usuarios pueden actualizar sus propios vehículos"
            ON public.vehiculos FOR UPDATE
            TO authenticated
            USING (auth.uid() = user_id)
            WITH CHECK (auth.uid() = user_id);
    END IF;

    -- Políticas para public.profiles
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'profiles' AND policyname = 'Usuarios pueden ver su propio perfil'
    ) THEN
        CREATE POLICY "Usuarios pueden ver su propio perfil"
            ON public.profiles FOR SELECT
            TO authenticated
            USING (auth.uid() = id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'profiles' AND policyname = 'Usuarios pueden actualizar su propio perfil'
    ) THEN
        CREATE POLICY "Usuarios pueden actualizar su propio perfil"
            ON public.profiles FOR UPDATE
            TO authenticated
            USING (auth.uid() = id)
            WITH CHECK (auth.uid() = id);
    END IF;

    -- Políticas para public.perfiles
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'perfiles' AND policyname = 'Usuarios pueden ver su propio perfiles'
    ) THEN
        CREATE POLICY "Usuarios pueden ver su propio perfiles"
            ON public.perfiles FOR SELECT
            TO authenticated
            USING (auth.uid() = id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'perfiles' AND policyname = 'Usuarios pueden actualizar su propio perfiles'
    ) THEN
        CREATE POLICY "Usuarios pueden actualizar su propio perfiles"
            ON public.perfiles FOR ALL
            TO authenticated
            USING (auth.uid() = id)
            WITH CHECK (auth.uid() = id);
    END IF;
END $$;
