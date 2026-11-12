-- =============================================================================
-- 20261112_add_motai_motorcycles_catalog.sql — CATÁLOGO EXPANDIDO DE MOTOS (MOTAI)
-- =============================================================================
-- Integra 62 modelos nuevos y 4 marcas oficiales con siluetas transparentes HD
-- almacenadas en Supabase Storage (catalog-assets).

-- 1. REGISTRO / ACTUALIZACIÓN DE MARCAS OFICIALES DE MOTOS
INSERT INTO public.catalogo_marcas (id, nombre, tipo, logo_url, color_hex, pais_origen, popularidad, activo)
VALUES
  ('benelli', 'Benelli', 'moto', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/benelli.png', '#005C30', 'Italia', 75, true),
  ('fratelli', 'Fratelli', 'moto', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/fratelli.png', '#C41230', 'Colombia', 60, true),
  ('kymco', 'Kymco', 'moto', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/kymco.png', '#E60012', 'Taiwán', 78, true),
  ('sym', 'SYM', 'moto', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/sym.png', '#005BAC', 'Taiwán', 70, true),
  ('royal_enfield', 'Royal Enfield', 'moto', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/logos/royal_enfield.png', '#8B1E1E', 'India', 82, true)
ON CONFLICT (id) DO UPDATE SET
  logo_url = EXCLUDED.logo_url,
  color_hex = EXCLUDED.color_hex,
  activo = EXCLUDED.activo;

-- 2. GARANTIZAR RESTRICCIÓN ÚNICA PARA EVITAR DUPLICADOS
CREATE UNIQUE INDEX IF NOT EXISTS idx_catalogo_modelos_unique_marca_linea_modelo
  ON public.catalogo_modelos(marca_id, tipo, modelo);

-- 3. INSERCIÓN DE 62 MODELOS NUEVOS DE MOTOS (MOTAI)
INSERT INTO public.catalogo_modelos (
  marca_id, tipo, linea, modelo, anio_inicio, cilindraje_cc, tipo_combustible,
  capacidad_tanque_gal, potencia_hp, aceite_recomendado, imagen_url, popularidad, activo
)
VALUES
  ('hero', 'moto', 'Hunk', 'Hunk 160 Stealth RS', 2025, 163, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/hero/hero_hunk_160_stealth_rs.png', 80, true),
  ('hero', 'moto', 'Hunk', 'Hunk 160 4V', 2025, 163, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/hero/hero_hunk_160_4v.png', 80, true),
  ('royal_enfield', 'moto', 'Hntr', 'Hntr 350', 2025, 349, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/royal_enfield/royal_enfield_hntr_350.png', 80, true),
  ('tvs', 'moto', 'Sport', 'Sport 110 FI', 2027, 110, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/tvs/tvs_sport_110_fi.png', 80, true),
  ('tvs', 'moto', 'Sport', 'Sport 100 ELS', 2027, 99, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/tvs/tvs_sport_100_els.png', 80, true),
  ('tvs', 'moto', 'Sport', 'Sport ELS As TK', 2027, 100, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/tvs/tvs_sport_els_as_tk.png', 80, true),
  ('fratelli', 'moto', 'Veloce', 'Veloce 125', 2027, 124, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/fratelli/fratelli_veloce_125.png', 80, true),
  ('tvs', 'moto', 'Neo', 'Neo 125 FI', 2027, 124, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/tvs/tvs_neo_125_fi.png', 80, true),
  ('tvs', 'moto', 'Neo', 'Neo Nx 110', 2027, 109, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/tvs/tvs_neo_nx_110.png', 80, true),
  ('tvs', 'moto', 'Sport', 'Sport 110 FI TK', 2027, 109, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/tvs/tvs_sport_110_fi_tk.png', 80, true),
  ('kawasaki', 'moto', 'ER400D', 'ER400D', 2022, 399, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/kawasaki/kawasaki_er400d.png', 80, true),
  ('victory', 'moto', 'Combat', 'Combat 100', 2025, 99, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/victory/victory_combat_100.png', 80, true),
  ('hero', 'moto', 'Eco', 'Eco 100', 2025, 98, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/hero/hero_eco_100.png', 80, true),
  ('victory', 'moto', 'MRX150', 'MRX150 CBS TK', 2027, 149, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/victory/victory_mrx150_cbs_tk.png', 80, true),
  ('victory', 'moto', 'MRX125', 'MRX125 S TK', 2026, 125, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/victory/victory_mrx125_s_tk.png', 80, true),
  ('victory', 'moto', 'MRX125', 'MRX125 S TK F', 2027, 124, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/victory/victory_mrx125_s_tk_f.png', 80, true),
  ('victory', 'moto', 'Nitro', 'Nitro 125 Facelift TK', 2027, 124, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/victory/victory_nitro_125_facelift_tk.png', 80, true),
  ('kymco', 'moto', 'Agility', 'Agility Fusion TK', 2027, 124, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/kymco/kymco_agility_fusion_tk.png', 80, true),
  ('victory', 'moto', 'One', 'One ST 100', 2023, 100, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/victory/victory_one_st_100.png', 80, true),
  ('victory', 'moto', 'MRX', 'MRX 125 S', 2027, 125, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/victory/victory_mrx_125_s.png', 80, true),
  ('honda', 'moto', 'Dio', 'Dio DLX 2 0', 2025, 110, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/honda/honda_dio_dlx_2_0.png', 80, true),
  ('victory', 'moto', 'Hunter', 'Hunter 150', 2025, 149, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/victory/victory_hunter_150.png', 80, true),
  ('victory', 'moto', 'Advance', 'Advance X1', 2024, 125, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/victory/victory_advance_x1.png', 80, true),
  ('victory', 'moto', 'MRX', 'MRX 200', 2025, 199, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/victory/victory_mrx_200.png', 80, true),
  ('kymco', 'moto', 'Agility', 'Agility Digital 3.0 AT', 2021, 124, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/kymco/kymco_agility_digital_3_0_at.png', 80, true),
  ('victory', 'moto', 'Bomber', 'Bomber 125', 2025, 124, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/victory/victory_bomber_125.png', 80, true),
  ('victory', 'moto', 'MRX125', 'MRX125 TK', 2025, 124, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/victory/victory_mrx125_tk.png', 80, true),
  ('hero', 'moto', 'Ignitor', 'Ignitor 5S MT', 2025, 125, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/hero/hero_ignitor_5s_mt.png', 80, true),
  ('benelli', 'moto', 'TRK', 'TRK 251', 2022, 249, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/benelli/benelli_trk_251.png', 80, true),
  ('victory', 'moto', 'One', 'One MP', 2023, 110, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/victory/victory_one_mp.png', 80, true),
  ('victory', 'moto', 'MRX200', 'MRX200 Fox TK', 2026, 199, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/victory/victory_mrx200_fox_tk.png', 80, true),
  ('tvs', 'moto', 'Sport', 'Sport KLS Spoke', 2025, 100, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/tvs/tvs_sport_kls_spoke.png', 80, true),
  ('hero', 'moto', 'Eco', 'Eco Deluxe CW MT', 2025, 100, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/hero/hero_eco_deluxe_cw_mt.png', 80, true),
  ('victory', 'moto', 'One', 'One MP TK', 2024, 100, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/victory/victory_one_mp_tk.png', 80, true),
  ('akt', 'moto', 'AK200DS', 'AK200DS EIII', 2024, 197, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/akt/akt_ak200ds_eiii.png', 80, true),
  ('victory', 'moto', 'MRX150', 'MRX150 Fox TK', 2026, 149, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/victory/victory_mrx150_fox_tk.png', 80, true),
  ('victory', 'moto', 'New', 'New Life 125 TK', 2024, 124, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/victory/victory_new_life_125_tk.png', 80, true),
  ('hero', 'moto', 'XPulse', 'XPulse 200 FI OC', 2024, 199, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/hero/hero_xpulse_200_fi_oc.png', 80, true),
  ('akt', 'moto', 'Ak', 'Ak 250RX3', 2021, 249, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/akt/akt_ak_250rx3.png', 80, true),
  ('benelli', 'moto', 'TNT', 'TNT 25N', 2023, 249, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/benelli/benelli_tnt_25n.png', 80, true),
  ('kymco', 'moto', 'Agility', 'Agility RS Naked', 2016, 124, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/kymco/kymco_agility_rs_naked.png', 80, true),
  ('sym', 'moto', 'XC15WX', 'XC15WX', 2025, 149, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/sym/sym_xc15wx.png', 80, true),
  ('honda', 'moto', 'Cb', 'Cb 125F', 2021, 124, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/honda/honda_cb_125f.png', 80, true),
  ('victory', 'moto', 'MRX', 'MRX 125 Camo', 2022, 125, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/victory/victory_mrx_125_camo.png', 80, true),
  ('victory', 'moto', 'Bomber', 'Bomber 125 TK MT', 2026, 124, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/victory/victory_bomber_125_tk_mt.png', 80, true),
  ('akt', 'moto', 'Sc-r', 'Sc-r', 2020, 125, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/akt/akt_sc_r.png', 80, true),
  ('victory', 'moto', 'Life', 'Life 125', 2024, 124, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/victory/victory_life_125.png', 80, true),
  ('bajaj', 'moto', 'Ct', 'Ct 100 Es Spoke', 2027, 102, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/bajaj/bajaj_ct_100_es_spoke.png', 80, true),
  ('victory', 'moto', 'MRX', 'MRX 125', 2024, 124, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/victory/victory_mrx_125.png', 80, true),
  ('victory', 'moto', 'Black', 'Black', 2023, 171, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/victory/victory_black.png', 80, true),
  ('hero', 'moto', 'Dash', 'Dash FI Ev', 2025, 125, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/hero/hero_dash_fi_ev.png', 80, true),
  ('benelli', 'moto', 'TNT', 'TNT 135', 2022, 135, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/benelli/benelli_tnt_135.png', 80, true),
  ('victory', 'moto', 'MRX', 'MRX Arizona Xplore', 2025, 200, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/victory/victory_mrx_arizona_xplore.png', 80, true),
  ('victory', 'moto', 'New', 'New Black', 2024, 171, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/victory/victory_new_black.png', 80, true),
  ('suzuki', 'moto', 'UR110', 'UR110', 2017, 112, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/suzuki/suzuki_ur110.png', 80, true),
  ('kymco', 'moto', 'Twist', 'Twist', 2026, 125, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/kymco/kymco_twist.png', 80, true),
  ('ktm', 'moto', 'SX', 'SX 250', 2019, 250, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/ktm/ktm_sx_250.png', 80, true),
  ('victory', 'moto', 'One', 'One ST 100 Silver', 2021, 99, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/victory/victory_one_st_100_silver.png', 80, true),
  ('hero', 'moto', 'Thriller', 'Thriller Pro', 2024, 150, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/hero/hero_thriller_pro.png', 80, true),
  ('benelli', 'moto', '180', '180 S', 2023, 175, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/benelli/benelli_180_s.png', 80, true),
  ('victory', 'moto', 'Bomber', 'Bomber 250', 2022, 250, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/victory/victory_bomber_250.png', 80, true),
  ('hero', 'moto', 'XPulse', 'XPulse 200T FI OC', 2025, 199, 'Gasolina', 3.0, 0.0, '20W-50 Semisintético', 'https://iqdobggghorpuepuquhb.supabase.co/storage/v1/object/public/catalog-assets/assets/motos/hero/hero_xpulse_200t_fi_oc.png', 80, true)
ON CONFLICT (marca_id, tipo, modelo) DO UPDATE SET
  imagen_url = EXCLUDED.imagen_url,
  cilindraje_cc = EXCLUDED.cilindraje_cc,
  anio_inicio = EXCLUDED.anio_inicio,
  activo = EXCLUDED.activo;

-- 4. REGISTRO OFICIAL DE ACTUALIZACIÓN OVER-THE-AIR (OTA) v1.2.13 BUILD 31
INSERT INTO public.app_versions (
  version_code, version_name, zip_url, release_notes, is_mandatory, min_supported_version
)
VALUES (
  31,
  '1.2.13',
  'https://github.com/INGJUANRUIZTOBON/my_auto_guide/releases/download/1.1.0/app-release.apk',
  '• Catálogo Motos Motai HD: 62 nuevos modelos de motocicletas con siluetas transparentes de alta resolución sin fondo.\n• 4 Nuevas Marcas Oficiales de Motos: Benelli, Kymco, SYM y Fratelli con logos vectorizados HD.\n• Catálogo Expandido de Motos: Nuevas líneas icónicas de Victory (Combat, MRX, Nitro, One ST), TVS (Sport 110, Neo), Hero (Hunk 160 4V, XPulse 200, Eco 100), AKT (AK200DS, Sc-r), Honda, Bajaj y Royal Enfield (Hntr 350).\n• Cero Peso Extra en el APK: 100% de siluetas de motos servidas dinámicamente desde el CDN de Supabase Storage.\n• Resiliencia Offline Completa: Mapeo de logos y colores oficiales para todas las marcas nuevas sin iconos rotos.',
  true,
  1
)
ON CONFLICT (version_code) DO UPDATE SET
  version_name = EXCLUDED.version_name,
  release_notes = EXCLUDED.release_notes,
  is_mandatory = EXCLUDED.is_mandatory;