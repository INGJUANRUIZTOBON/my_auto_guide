-- =============================================================================
-- add_runt_full_data.sql — Ficha completa del RUNT en tabla public.vehiculos
-- =============================================================================

ALTER TABLE public.vehiculos
    ADD COLUMN IF NOT EXISTS runt_data JSONB DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS runt_last_check TIMESTAMPTZ DEFAULT NULL;
