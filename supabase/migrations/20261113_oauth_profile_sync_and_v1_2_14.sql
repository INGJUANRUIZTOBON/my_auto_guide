-- =============================================================================
-- 20261113_oauth_profile_sync_and_v1_2_14.sql
-- MY AUTO GUIDE v1.2.14 (Build 32)
-- Sincronización Automática de Perfiles OAuth (Google / Facebook) + RLS + Versionado
-- =============================================================================
-- Ejecutar en: Supabase Dashboard -> SQL Editor -> Run

-- 1. Asegurar tabla public.perfiles con soporte para Avatares y Nombres de OAuth
CREATE TABLE IF NOT EXISTS public.perfiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    nombre TEXT,
    avatar_url TEXT,
    fcm_token TEXT,
    cedula_hash TEXT,
    driver_license_data JSONB DEFAULT NULL,
    licencia_vencimiento TEXT DEFAULT NULL,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Asegurar columnas si la tabla ya existía
ALTER TABLE public.perfiles
    ADD COLUMN IF NOT EXISTS email TEXT,
    ADD COLUMN IF NOT EXISTS nombre TEXT,
    ADD COLUMN IF NOT EXISTS avatar_url TEXT,
    ADD COLUMN IF NOT EXISTS fcm_token TEXT,
    ADD COLUMN IF NOT EXISTS cedula_hash TEXT,
    ADD COLUMN IF NOT EXISTS driver_license_data JSONB DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS licencia_vencimiento TEXT DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

-- 2. Habilitar Row Level Security (RLS) en public.perfiles
ALTER TABLE public.perfiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Usuarios pueden ver su propio perfil" ON public.perfiles;
CREATE POLICY "Usuarios pueden ver su propio perfil"
    ON public.perfiles FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "Usuarios pueden insertar su propio perfil" ON public.perfiles;
CREATE POLICY "Usuarios pueden insertar su propio perfil"
    ON public.perfiles FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Usuarios pueden actualizar su propio perfil" ON public.perfiles;
CREATE POLICY "Usuarios pueden actualizar su propio perfil"
    ON public.perfiles FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- 3. Trigger en PostgreSQL para sincronizar automáticamente usuarios de Google / Facebook / Email
-- Al registrarse o iniciar sesión con OAuth, extrae automáticamente el nombre y la foto del proveedor
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER AS $$
DECLARE
    user_name TEXT;
    user_avatar TEXT;
BEGIN
    -- Extraer nombre del metadata de Supabase Auth (funciona para Google, Facebook y Email)
    user_name := COALESCE(
        NEW.raw_user_meta_data->>'name',
        NEW.raw_user_meta_data->>'full_name',
        NEW.raw_user_meta_data->>'user_name',
        split_part(NEW.email, '@', 1)
    );

    -- Extraer foto del perfil social si existe
    user_avatar := COALESCE(
        NEW.raw_user_meta_data->>'avatar_url',
        NEW.raw_user_meta_data->>'picture'
    );

    -- Insertar o actualizar perfil en public.perfiles
    INSERT INTO public.perfiles (id, email, nombre, avatar_url, updated_at)
    VALUES (NEW.id, NEW.email, user_name, user_avatar, timezone('utc'::text, now()))
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        nombre = COALESCE(public.perfiles.nombre, EXCLUDED.nombre),
        avatar_url = COALESCE(EXCLUDED.avatar_url, public.perfiles.avatar_url),
        updated_at = timezone('utc'::text, now());

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recrear el Trigger
DROP TRIGGER IF EXISTS on_auth_user_created_sync_profile ON auth.users;
CREATE TRIGGER on_auth_user_created_sync_profile
    AFTER INSERT OR UPDATE ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_auth_user();

-- 4. Registrar la nueva versión v1.2.14+32 en app_versions (Actualización OTA / Novedades)
INSERT INTO public.app_versions (
    version_code,
    version_name,
    zip_url,
    release_notes,
    is_mandatory,
    min_supported_version
)
VALUES (
    32,
    '1.2.14',
    'https://github.com/INGJUANRUIZTOBON/my_auto_guide/releases/download/1.2.14/app-release.apk',
    '• Nuevo Diseño Obsidian Cyberpunk Glassmorphism en Pico y Placa con alertas cromáticas dinámicas (Rojo, Ámbar, Cian).
• Mantenimientos Personalizados integrados al carrusel principal superior junto a Aceite, Cadena, SOAT y Tecno.
• Nuevo Modal de Odómetro Digital para actualización de kilometraje en Dark Obsidian con recordatorio inteligente a las 4-5 horas.
• Pantalla de Registro renovada con el Logo Oficial Holográfico de My Auto Guide y aceptación legal de Términos, Condiciones y Habeas Data.
• Integración y soporte completo de inicio de sesión social con Google (Gmail) y Facebook.',
    false,
    1
)
ON CONFLICT (version_code) DO UPDATE SET
    version_name = EXCLUDED.version_name,
    release_notes = EXCLUDED.release_notes,
    is_mandatory = EXCLUDED.is_mandatory;
