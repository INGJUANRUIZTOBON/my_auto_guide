/**
 * =============================================================================
 * INGESTOR DEL CATÁLOGO DE VEHÍCULOS (MY AUTO GUIDE)
 * =============================================================================
 * Script de Node.js (v18+) sin dependencias externas para inyectar marcas y modelos
 * en Supabase PostgREST (Tablas: catalogo_marcas y catalogo_modelos).
 *
 * USO:
 *   $env:SUPABASE_URL="https://tu-proyecto.supabase.co"
 *   $env:SUPABASE_SERVICE_KEY="tu-service-role-key"
 *   node scripts/ingest_catalog.js
 *
 * O con parámetros:
 *   node scripts/ingest_catalog.js --url=https://... --key=... [--dry-run]
 * =============================================================================
 */

const fs = require('fs');
const path = require('path');

// 1. Obtener Credenciales
const args = process.argv.slice(2).reduce((acc, arg) => {
  const [k, v] = arg.replace(/^--/, '').split('=');
  acc[k] = v || true;
  return acc;
}, {});

const SUPABASE_URL = args.url || process.env.SUPABASE_URL;
const SUPABASE_KEY = args.key || process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_ANON_KEY;
const IS_DRY_RUN = Boolean(args['dry-run']);

if (!IS_DRY_RUN && (!SUPABASE_URL || !SUPABASE_KEY)) {
  console.error('\x1b[31m[ERROR] Faltan SUPABASE_URL o SUPABASE_KEY.\x1b[0m');
  console.log('Uso: node scripts/ingest_catalog.js --url=https://... --key=tu_key');
  console.log('O define variables de entorno: SUPABASE_URL y SUPABASE_SERVICE_KEY');
  process.exit(1);
}

// 2. Clientes HTTP PostgREST nativos
async function postgrestRequest(endpoint, method, body) {
  if (IS_DRY_RUN) {
    console.log(`[DRY-RUN] ${method} ${endpoint}`, body);
    return { ok: true, status: 200, json: async () => body };
  }

  const url = `${SUPABASE_URL}/rest/v1/${endpoint}`;
  const response = await fetch(url, {
    method,
    headers: {
      'apikey': SUPABASE_KEY,
      'Authorization': `Bearer ${SUPABASE_KEY}`,
      'Content-Type': 'application/json',
      'Prefer': 'resolution=merge-duplicates,return=representation'
    },
    body: JSON.stringify(body)
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`[${response.status}] ${response.statusText}: ${errorText}`);
  }

  return response.json();
}

/**
 * Inserta o actualiza una marca en catalogo_marcas
 */
async function upsertBrand(brand) {
  return postgrestRequest('catalogo_marcas', 'POST', {
    nombre: brand.nombre,
    tipo: brand.tipo, // 'moto' | 'carro' | 'ambos'
    pais_origen: brand.pais_origen || null,
    color_hex: brand.color_hex || '#00E5FF',
    logo_url: brand.logo_url || null,
    popularidad: brand.popularidad || 50,
    activo: brand.activo !== undefined ? brand.activo : true,
    updated_at: new Date().toISOString()
  });
}

/**
 * Inserta o actualiza un modelo en catalogo_modelos
 */
async function upsertModel(model) {
  return postgrestRequest('catalogo_modelos', 'POST', {
    marca_id: model.marca_id,
    linea: model.linea,
    version: model.version || null,
    anio_inicio: model.anio_inicio || 2015,
    anio_fin: model.anio_fin || null,
    tipo_vehiculo: model.tipo_vehiculo, // 'moto' | 'carro'
    cilindraje_cc: model.cilindraje_cc || null,
    tipo_combustible: model.tipo_combustible || 'Gasolina',
    capacidad_tanque_gal: model.capacidad_tanque_gal || null,
    potencia_hp: model.potencia_hp || null,
    torque_nm: model.torque_nm || null,
    aceite_recomendado: model.aceite_recomendado || null,
    tipo_transmision: model.tipo_transmision || 'Manual',
    peso_kg: model.peso_kg || null,
    foto_estudio_url: model.foto_estudio_url || null,
    activo: model.activo !== undefined ? model.activo : true,
    updated_at: new Date().toISOString()
  });
}

// 3. Catálogo de Ejemplo Adicional listo para ser inyectado
const CATALOG_BATCH = [
  {
    marca: {
      nombre: 'Yamaha',
      tipo: 'moto',
      pais_origen: 'Japón',
      color_hex: '#002BFF',
      logo_url: 'https://images.myautoguide.app/logos/yamaha.png',
      popularidad: 99
    },
    modelos: [
      {
        linea: 'FZ-25',
        version: 'ABS',
        anio_inicio: 2018,
        tipo_vehiculo: 'moto',
        cilindraje_cc: 249,
        tipo_combustible: 'Gasolina Corriente',
        capacidad_tanque_gal: 3.7,
        potencia_hp: 20.6,
        torque_nm: 20.0,
        aceite_recomendado: '10W-40 Semisintético Yamalube',
        tipo_transmision: 'Manual 5 vel',
        foto_estudio_url: 'https://images.myautoguide.app/models/yamaha_fz25.webp'
      },
      {
        linea: 'MT-03',
        version: 'ABS',
        anio_inicio: 2019,
        tipo_vehiculo: 'moto',
        cilindraje_cc: 321,
        tipo_combustible: 'Gasolina Extra',
        capacidad_tanque_gal: 3.7,
        potencia_hp: 41.4,
        torque_nm: 29.6,
        aceite_recomendado: '10W-40 100% Sintético Yamalube',
        tipo_transmision: 'Manual 6 vel',
        foto_estudio_url: 'https://images.myautoguide.app/models/yamaha_mt03.webp'
      }
    ]
  },
  {
    marca: {
      nombre: 'Toyota',
      tipo: 'carro',
      pais_origen: 'Japón',
      color_hex: '#EB0A1E',
      logo_url: 'https://images.myautoguide.app/logos/toyota.png',
      popularidad: 98
    },
    modelos: [
      {
        linea: 'Corolla Cross',
        version: 'HEV XEI / SEG',
        anio_inicio: 2021,
        tipo_vehiculo: 'carro',
        cilindraje_cc: 1798,
        tipo_combustible: 'Híbrido Gasolina',
        capacidad_tanque_gal: 9.5,
        potencia_hp: 126.0,
        torque_nm: 142.0,
        aceite_recomendado: '0W-20 Sintético Toyota Genuine',
        tipo_transmision: 'e-CVT Automática',
        foto_estudio_url: 'https://images.myautoguide.app/models/toyota_corolla_cross.webp'
      }
    ]
  }
];

// 4. Proceso de Ingesta Principal
async function main() {
  console.log('\x1b[36m====================================================\x1b[0m');
  console.log('\x1b[36m  MY AUTO GUIDE • VEHICLE CATALOG INGESTOR API      \x1b[0m');
  console.log('\x1b[36m====================================================\x1b[0m');
  console.log(`Endpoint: ${SUPABASE_URL || 'DRY-RUN'}`);

  let marcasCount = 0;
  let modelosCount = 0;

  for (const item of CATALOG_BATCH) {
    try {
      console.log(`\n📌 Procesando Marca: \x1b[32m${item.marca.nombre}\x1b[0m (${item.marca.tipo})`);
      const brandRes = await upsertBrand(item.marca);
      const marcaId = (brandRes && brandRes[0] && brandRes[0].id) ? brandRes[0].id : null;
      marcasCount++;

      for (const m of item.modelos) {
        if (marcaId) m.marca_id = marcaId;
        console.log(`   🚗 Inyectando Modelo: ${m.linea} ${m.version || ''} (${m.cilindraje_cc}cc)`);
        await upsertModel(m);
        modelosCount++;
      }
    } catch (err) {
      console.error(`\x1b[31m[ERROR] Falló al inyectar ${item.marca.nombre}: ${err.message}\x1b[0m`);
    }
  }

  console.log('\n\x1b[32m✔ Proceso de ingesta finalizado con éxito.\x1b[0m');
  console.log(`  Marcas actualizadas: ${marcasCount}`);
  console.log(`  Modelos actualizados: ${modelosCount}`);
}

main().catch(console.error);
