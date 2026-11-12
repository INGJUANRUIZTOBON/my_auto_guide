// =============================================================================
// fix_and_complete_supabase_catalog.js
// =============================================================================
// 1. Corrige las URLs de logos en `catalogo_marcas` (eliminando URLs duplicadas).
// 2. Inserta todos los modelos faltantes en `catalogo_modelos` con URLs públicas de CDN.
// =============================================================================

const SUPABASE_URL = 'https://iqdobggghorpuepuquhb.supabase.co';
const SUPABASE_KEY = 'sb_secret_3g9hjQsbxUFhwvsx-32qjQ_fi-l7MoD';
const BASE_STORAGE = `${SUPABASE_URL}/storage/v1/object/public/catalog-assets`;

const BRAND_LOGOS = {
  bajaj: 'assets/logos/bajaj_logo.png',
  yamaha: 'assets/logos/yamaha_logo.png',
  akt: 'assets/logos/akt_logo.png',
  suzuki: 'assets/logos/suzuki_logo.png',
  honda: 'assets/logos/honda_logo.png',
  tvs: 'assets/logos/tvs_logo.png',
  ktm: 'assets/logos/ktm_logo.png',
  hero: 'assets/logos/hero_logo.png',
  kawasaki: 'assets/logos/kawa_logo.png',
  victory: 'assets/logos/victori_logo.png',
  bmw: 'assets/logos/bmw_logo.png',
  renault: 'assets/logos/renault_logo.png',
  chevrolet: 'assets/logos/chevrolet_logo.png',
  toyota: 'assets/logos/toyota_logo.png',
  mazda: 'assets/logos/mazda_logo.png',
  kia: 'assets/logos/kia_logo.png',
  nissan: 'assets/logos/nissan_logo.png',
  volkswagen: 'assets/logos/volkswagen_logo.png',
  ford: 'assets/logos/ford_logo.png',
  hyundai: 'assets/logos/hyundai_logo.png',
  byd: 'assets/logos/byd_logo.png',
  royal_enfield: 'assets/logos/royal-enfield.png'
};

const ADDITIONAL_MODELS = [
  // KIA Faltante
  {
    marca_id: 'kia',
    tipo: 'carro',
    linea: 'Seltos',
    modelo: 'Seltos Emotion / Zenith 1.6 / 2.0',
    anio_inicio: 2020,
    cilindraje_cc: 1999,
    tipo_combustible: 'Gasolina',
    capacidad_tanque_gal: 13.2,
    potencia_hp: 147,
    aceite_recomendado: '5W-20 Sintético',
    imagen_url: `${BASE_STORAGE}/assets/carros/kia/seltos.png`,
    popularidad: 95,
    activo: true
  },
  // CHEVROLET Faltantes
  {
    marca_id: 'chevrolet',
    tipo: 'carro',
    linea: 'Montana',
    modelo: 'Montana Premier 1.2 Turbo',
    anio_inicio: 2023,
    cilindraje_cc: 1199,
    tipo_combustible: 'Gasolina',
    capacidad_tanque_gal: 11.6,
    potencia_hp: 130,
    aceite_recomendado: '0W-20 Dexos 1 Gen 3',
    imagen_url: `${BASE_STORAGE}/assets/carros/chevrolet/Montana.png`,
    popularidad: 88,
    activo: true
  },
  {
    marca_id: 'chevrolet',
    tipo: 'carro',
    linea: 'Traverse',
    modelo: 'Traverse RS 3.6 V6 AWD',
    anio_inicio: 2018,
    cilindraje_cc: 3564,
    tipo_combustible: 'Gasolina',
    capacidad_tanque_gal: 21.7,
    potencia_hp: 310,
    aceite_recomendado: '5W-30 Dexos 1',
    imagen_url: `${BASE_STORAGE}/assets/carros/chevrolet/traverse.png`,
    popularidad: 82,
    activo: true
  },
  {
    marca_id: 'chevrolet',
    tipo: 'carro',
    linea: 'Silverado',
    modelo: 'Silverado RST V8 5.3 4x4',
    anio_inicio: 2021,
    cilindraje_cc: 5328,
    tipo_combustible: 'Gasolina',
    capacidad_tanque_gal: 24.0,
    potencia_hp: 355,
    aceite_recomendado: '0W-20 Dexos 1',
    imagen_url: `${BASE_STORAGE}/assets/carros/chevrolet/silverado.png`,
    popularidad: 80,
    activo: true
  },
  // TOYOTA Faltantes
  {
    marca_id: 'toyota',
    tipo: 'carro',
    linea: 'Yaris',
    modelo: 'Yaris Hatchback XLS',
    anio_inicio: 2018,
    cilindraje_cc: 1496,
    tipo_combustible: 'Gasolina',
    capacidad_tanque_gal: 11.1,
    potencia_hp: 106,
    aceite_recomendado: '0W-20 Sintético',
    imagen_url: `${BASE_STORAGE}/assets/carros/toyota/yaris.png`,
    popularidad: 92,
    activo: true
  },
  {
    marca_id: 'toyota',
    tipo: 'carro',
    linea: 'Tundra',
    modelo: 'Tundra Platinum 3.5 V6 i-FORCE',
    anio_inicio: 2022,
    cilindraje_cc: 3444,
    tipo_combustible: 'Gasolina',
    capacidad_tanque_gal: 32.2,
    potencia_hp: 389,
    aceite_recomendado: '0W-20 Sintético',
    imagen_url: `${BASE_STORAGE}/assets/carros/toyota/tundra.png`,
    popularidad: 85,
    activo: true
  },
  // YAMAHA Faltantes
  {
    marca_id: 'yamaha',
    tipo: 'moto',
    linea: 'BWS',
    modelo: 'BWS FI 125',
    anio_inicio: 2016,
    cilindraje_cc: 125,
    tipo_combustible: 'Gasolina',
    capacidad_tanque_gal: 1.7,
    potencia_hp: 9.6,
    aceite_recomendado: '10W-40 Yamalube 4T',
    imagen_url: `${BASE_STORAGE}/assets/motos/yamaha/bws125.png`,
    popularidad: 99,
    activo: true
  },
  {
    marca_id: 'yamaha',
    tipo: 'moto',
    linea: 'Aerox',
    modelo: 'Aerox 155 Connected',
    anio_inicio: 2022,
    cilindraje_cc: 155,
    tipo_combustible: 'Gasolina',
    capacidad_tanque_gal: 1.45,
    potencia_hp: 15.1,
    aceite_recomendado: '10W-40 Yamalube AT',
    imagen_url: `${BASE_STORAGE}/assets/motos/yamaha/aerox155.png`,
    popularidad: 96,
    activo: true
  },
  {
    marca_id: 'yamaha',
    tipo: 'moto',
    linea: 'MT',
    modelo: 'MT 09 ABS',
    anio_inicio: 2019,
    cilindraje_cc: 890,
    tipo_combustible: 'Gasolina',
    capacidad_tanque_gal: 3.7,
    potencia_hp: 119,
    aceite_recomendado: '10W-40 Yamalube Full Sintético',
    imagen_url: `${BASE_STORAGE}/assets/motos/yamaha/mt09.png`,
    popularidad: 90,
    activo: true
  },
  {
    marca_id: 'yamaha',
    tipo: 'moto',
    linea: 'XTZ',
    modelo: 'XTZ 250 Lander ABS',
    anio_inicio: 2020,
    cilindraje_cc: 249,
    tipo_combustible: 'Gasolina',
    capacidad_tanque_gal: 3.6,
    potencia_hp: 20.4,
    aceite_recomendado: '20W-50 Yamalube 4T',
    imagen_url: `${BASE_STORAGE}/assets/motos/yamaha/xtz250.png`,
    popularidad: 94,
    activo: true
  },
  // AKT Faltantes
  {
    marca_id: 'akt',
    tipo: 'moto',
    linea: 'CR4',
    modelo: 'CR4 150',
    anio_inicio: 2018,
    cilindraje_cc: 149,
    tipo_combustible: 'Gasolina',
    capacidad_tanque_gal: 3.3,
    potencia_hp: 12.0,
    aceite_recomendado: '20W-50 4T Mineral',
    imagen_url: `${BASE_STORAGE}/assets/motos/akt/CR4_150.png`,
    popularidad: 95,
    activo: true
  },
  {
    marca_id: 'akt',
    tipo: 'moto',
    linea: 'CR4',
    modelo: 'CR4 200',
    anio_inicio: 2021,
    cilindraje_cc: 197,
    tipo_combustible: 'Gasolina',
    capacidad_tanque_gal: 3.3,
    potencia_hp: 16.5,
    aceite_recomendado: '20W-50 4T Mineral',
    imagen_url: `${BASE_STORAGE}/assets/motos/akt/CR4_200.png`,
    popularidad: 92,
    activo: true
  },
  {
    marca_id: 'akt',
    tipo: 'moto',
    linea: 'TTR',
    modelo: 'TTR 125',
    anio_inicio: 2017,
    cilindraje_cc: 124,
    tipo_combustible: 'Gasolina',
    capacidad_tanque_gal: 2.9,
    potencia_hp: 10.0,
    aceite_recomendado: '20W-50 4T Mineral',
    imagen_url: `${BASE_STORAGE}/assets/motos/akt/ttr125.png`,
    popularidad: 90,
    activo: true
  },
  {
    marca_id: 'akt',
    tipo: 'moto',
    linea: 'Special',
    modelo: 'Special 100',
    anio_inicio: 2015,
    cilindraje_cc: 99,
    tipo_combustible: 'Gasolina',
    capacidad_tanque_gal: 2.1,
    potencia_hp: 7.2,
    aceite_recomendado: '20W-50 4T Mineral',
    imagen_url: `${BASE_STORAGE}/assets/motos/akt/special100.png`,
    popularidad: 88,
    activo: true
  },
  {
    marca_id: 'akt',
    tipo: 'moto',
    linea: '250',
    modelo: '250 R',
    anio_inicio: 2023,
    cilindraje_cc: 249,
    tipo_combustible: 'Gasolina',
    capacidad_tanque_gal: 3.4,
    potencia_hp: 25.0,
    aceite_recomendado: '10W-40 Semisintético',
    imagen_url: `${BASE_STORAGE}/assets/motos/akt/250R.png`,
    popularidad: 86,
    activo: true
  },
  {
    marca_id: 'akt',
    tipo: 'moto',
    linea: 'Mawi',
    modelo: 'Mawi 125',
    anio_inicio: 2022,
    cilindraje_cc: 124,
    tipo_combustible: 'Gasolina',
    capacidad_tanque_gal: 1.5,
    potencia_hp: 7.1,
    aceite_recomendado: '10W-40 AT',
    imagen_url: `${BASE_STORAGE}/assets/motos/akt/mawi.png`,
    popularidad: 85,
    activo: true
  },
  // SUZUKI MOTOS Faltantes
  {
    marca_id: 'suzuki',
    tipo: 'moto',
    linea: 'Gixxer',
    modelo: 'Gixxer 250 FI ABS',
    anio_inicio: 2021,
    cilindraje_cc: 249,
    tipo_combustible: 'Gasolina',
    capacidad_tanque_gal: 3.17,
    potencia_hp: 26.5,
    aceite_recomendado: '10W-40 ECSTAR 4T',
    imagen_url: `${BASE_STORAGE}/assets/motos/suzuki/gixxer250.png`,
    popularidad: 95,
    activo: true
  },
  {
    marca_id: 'suzuki',
    tipo: 'moto',
    linea: 'Gixxer',
    modelo: 'Gixxer SF 250 FI ABS',
    anio_inicio: 2021,
    cilindraje_cc: 249,
    tipo_combustible: 'Gasolina',
    capacidad_tanque_gal: 3.17,
    potencia_hp: 26.5,
    aceite_recomendado: '10W-40 ECSTAR 4T',
    imagen_url: `${BASE_STORAGE}/assets/motos/suzuki/gixxersf250.png`,
    popularidad: 93,
    activo: true
  },
  {
    marca_id: 'suzuki',
    tipo: 'moto',
    linea: 'Address',
    modelo: 'Address 125 FI',
    anio_inicio: 2022,
    cilindraje_cc: 124,
    tipo_combustible: 'Gasolina',
    capacidad_tanque_gal: 1.37,
    potencia_hp: 8.7,
    aceite_recomendado: '10W-40 Scooter',
    imagen_url: `${BASE_STORAGE}/assets/motos/suzuki/address125.png`,
    popularidad: 90,
    activo: true
  },
  {
    marca_id: 'suzuki',
    tipo: 'moto',
    linea: 'Burgman',
    modelo: 'Burgman 125 FI',
    anio_inicio: 2021,
    cilindraje_cc: 124,
    tipo_combustible: 'Gasolina',
    capacidad_tanque_gal: 1.45,
    potencia_hp: 8.6,
    aceite_recomendado: '10W-40 Scooter',
    imagen_url: `${BASE_STORAGE}/assets/motos/suzuki/burgman.png`,
    popularidad: 89,
    activo: true
  },
  {
    marca_id: 'suzuki',
    tipo: 'moto',
    linea: 'Hayabusa',
    modelo: 'Hayabusa GSX 1300R',
    anio_inicio: 2021,
    cilindraje_cc: 1340,
    tipo_combustible: 'Gasolina',
    capacidad_tanque_gal: 5.28,
    potencia_hp: 190,
    aceite_recomendado: '10W-40 Full Sintético',
    imagen_url: `${BASE_STORAGE}/assets/motos/suzuki/hayabusa.png`,
    popularidad: 85,
    activo: true
  },
  // TVS Faltantes
  {
    marca_id: 'tvs',
    tipo: 'moto',
    linea: 'Apache',
    modelo: 'Apache RTR 310',
    anio_inicio: 2023,
    cilindraje_cc: 312,
    tipo_combustible: 'Gasolina',
    capacidad_tanque_gal: 2.9,
    potencia_hp: 35.6,
    aceite_recomendado: '10W-50 TRU4 Full Sintético',
    imagen_url: `${BASE_STORAGE}/assets/motos/tvs/apache310.png`,
    popularidad: 93,
    activo: true
  },
  {
    marca_id: 'tvs',
    tipo: 'moto',
    linea: 'Ronin',
    modelo: 'Ronin 225',
    anio_inicio: 2023,
    cilindraje_cc: 225,
    tipo_combustible: 'Gasolina',
    capacidad_tanque_gal: 3.7,
    potencia_hp: 20.4,
    aceite_recomendado: '10W-40 TRU4 Semisintético',
    imagen_url: `${BASE_STORAGE}/assets/motos/tvs/ronin225.png`,
    popularidad: 91,
    activo: true
  },
  // VICTORY Modelos
  {
    marca_id: 'victory',
    tipo: 'moto',
    linea: 'One',
    modelo: 'Victory One MP 100',
    anio_inicio: 2019,
    cilindraje_cc: 99,
    tipo_combustible: 'Gasolina',
    capacidad_tanque_gal: 2.6,
    potencia_hp: 7.4,
    aceite_recomendado: '20W-50 4T Mineral',
    imagen_url: `${BASE_STORAGE}/assets/motos/victori/victori_one_mp.png`,
    popularidad: 94,
    activo: true
  },
  {
    marca_id: 'victory',
    tipo: 'moto',
    linea: 'Venom',
    modelo: 'Victory Venom 150',
    anio_inicio: 2020,
    cilindraje_cc: 149,
    tipo_combustible: 'Gasolina',
    capacidad_tanque_gal: 3.1,
    potencia_hp: 11.5,
    aceite_recomendado: '20W-50 4T Semisintético',
    imagen_url: `${BASE_STORAGE}/assets/motos/victori/victori_venom_150.png`,
    popularidad: 90,
    activo: true
  },
  // KTM Faltantes
  {
    marca_id: 'ktm',
    tipo: 'moto',
    linea: 'Duke',
    modelo: 'Duke 990',
    anio_inicio: 2024,
    cilindraje_cc: 947,
    tipo_combustible: 'Gasolina',
    capacidad_tanque_gal: 3.8,
    potencia_hp: 123,
    aceite_recomendado: '10W-50 Motorex Cross Power 4T',
    imagen_url: `${BASE_STORAGE}/assets/motos/ktm/KTM-990-DUKE.png`,
    popularidad: 88,
    activo: true
  },
  {
    marca_id: 'ktm',
    tipo: 'moto',
    linea: 'Super Duke',
    modelo: '1390 Super Duke R 2025',
    anio_inicio: 2024,
    cilindraje_cc: 1350,
    tipo_combustible: 'Gasolina',
    capacidad_tanque_gal: 4.6,
    potencia_hp: 190,
    aceite_recomendado: '10W-50 Motorex Power Synt 4T',
    imagen_url: `${BASE_STORAGE}/assets/motos/ktm/KTM1390superduke2025.png`,
    popularidad: 85,
    activo: true
  }
];

async function updateBrandLogos() {
  console.log('📌 1. Actualizando URLs limpias de logos en catalogo_marcas...');
  for (const [marcaId, relativeLogo] of Object.entries(BRAND_LOGOS)) {
    const cleanUrl = `${BASE_STORAGE}/${relativeLogo}`;
    const res = await fetch(`${SUPABASE_URL}/rest/v1/catalogo_marcas?id=eq.${marcaId}`, {
      method: 'PATCH',
      headers: {
        'apikey': SUPABASE_KEY,
        'Authorization': `Bearer ${SUPABASE_KEY}`,
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal'
      },
      body: JSON.stringify({ logo_url: cleanUrl })
    });
    if (res.ok) {
      console.log(`  ✔ Logo ${marcaId} -> ${cleanUrl}`);
    } else {
      console.error(`  ❌ Error en ${marcaId}:`, await res.text());
    }
  }
}

async function insertAdditionalModels() {
  console.log('\n📌 2. Insertando modelos faltantes en catalogo_modelos...');
  let inserted = 0;
  for (const mod of ADDITIONAL_MODELS) {
    // Comprobar si ya existe por modelo y marca
    const checkRes = await fetch(`${SUPABASE_URL}/rest/v1/catalogo_modelos?marca_id=eq.${mod.marca_id}&modelo=eq.${encodeURIComponent(mod.modelo)}`, {
      headers: {
        'apikey': SUPABASE_KEY,
        'Authorization': `Bearer ${SUPABASE_KEY}`
      }
    });
    const exists = await checkRes.json();
    if (exists && exists.length > 0) {
      // Actualizar imagen_url
      await fetch(`${SUPABASE_URL}/rest/v1/catalogo_modelos?id=eq.${exists[0].id}`, {
        method: 'PATCH',
        headers: {
          'apikey': SUPABASE_KEY,
          'Authorization': `Bearer ${SUPABASE_KEY}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ imagen_url: mod.imagen_url, activo: true })
      });
      console.log(`  🔄 Actualizado: [${mod.marca_id.toUpperCase()}] ${mod.modelo}`);
      inserted++;
    } else {
      // Insertar nuevo
      const insertRes = await fetch(`${SUPABASE_URL}/rest/v1/catalogo_modelos`, {
        method: 'POST',
        headers: {
          'apikey': SUPABASE_KEY,
          'Authorization': `Bearer ${SUPABASE_KEY}`,
          'Content-Type': 'application/json',
          'Prefer': 'return=representation'
        },
        body: JSON.stringify(mod)
      });
      if (insertRes.ok) {
        console.log(`  ✔ Insertado nuevo: [${mod.marca_id.toUpperCase()}] ${mod.modelo}`);
        inserted++;
      } else {
        console.error(`  ❌ Error insertando ${mod.modelo}:`, await insertRes.text());
      }
    }
  }
  console.log(`\n✔ ¡${inserted} modelos procesados/insertados en Supabase!`);
}

async function main() {
  console.log('============================================================');
  console.log('🚀 SINCRONIZANDO MARCAS Y MODELOS COMPLETOS EN SUPABASE');
  console.log('============================================================\n');
  await updateBrandLogos();
  await insertAdditionalModels();
  console.log('\n🎉 ¡MIGRACIÓN DE BASE DE DATOS FINALIZADA CON ÉXITO!');
}

main().catch(console.error);
