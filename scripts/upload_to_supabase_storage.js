// =============================================================================
// upload_to_supabase_storage.js — SUBIDOR AUTOMÁTICO DE ASSETS A SUPABASE
// =============================================================================
// Sube automáticamente todos los logos de marcas y fotos de modelos transparentes
// desde la carpeta local `assets/` directamente al Bucket `catalog-assets` de Supabase.
//
// USO:
//   node scripts/upload_to_supabase_storage.js --url=https://xyz.supabase.co --key=tu-service-key
// O en seco para verificar:
//   node scripts/upload_to_supabase_storage.js --dry-run
// =============================================================================

const fs = require('fs');
const path = require('path');

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
  console.log('Uso: node scripts/upload_to_supabase_storage.js --url=https://xyz.supabase.co --key=tu_service_key');
  console.log('O prueba en seco: node scripts/upload_to_supabase_storage.js --dry-run');
  process.exit(1);
}

const BUCKET = 'catalog-assets';

// 1. Mapa de Marcas con sus logos locales
const BRAND_LOGOS = [
  { id: 'bajaj', file: 'assets/logos/bajaj_logo.png', dest: 'logos/bajaj.png' },
  { id: 'yamaha', file: 'assets/logos/yamaha_logo.png', dest: 'logos/yamaha.png' },
  { id: 'akt', file: 'assets/logos/akt_logo.png', dest: 'logos/akt.png' },
  { id: 'suzuki', file: 'assets/logos/suzuki_logo.png', dest: 'logos/suzuki.png' },
  { id: 'honda', file: 'assets/logos/honda_logo.png', dest: 'logos/honda.png' },
  { id: 'tvs', file: 'assets/logos/tvs_logo.png', dest: 'logos/tvs.png' },
  { id: 'hero', file: 'assets/logos/hero_logo.png', dest: 'logos/hero.png' },
  { id: 'ktm', file: 'assets/logos/ktm_logo.png', dest: 'logos/ktm.png' },
  { id: 'victory', file: 'assets/logos/victori_logo.png', dest: 'logos/victory.png' },
  { id: 'bmw', file: 'assets/logos/bmw_logo.png', dest: 'logos/bmw.png' },
  { id: 'renault', file: 'assets/logos/renault_logo.png', dest: 'logos/renault.png' },
  { id: 'chevrolet', file: 'assets/logos/chevrolet_logo.png', dest: 'logos/chevrolet.png' },
  { id: 'toyota', file: 'assets/logos/toyota_logo.png', dest: 'logos/toyota.png' },
  { id: 'mazda', file: 'assets/logos/mazda_logo.png', dest: 'logos/mazda.png' },
  { id: 'kia', file: 'assets/logos/kia_logo.png', dest: 'logos/kia.png' },
  { id: 'nissan', file: 'assets/logos/nissan_logo.png', dest: 'logos/nissan.png' },
  { id: 'volkswagen', file: 'assets/logos/volkswagen_logo.png', dest: 'logos/volkswagen.png' },
  { id: 'ford', file: 'assets/logos/ford_logo.png', dest: 'logos/ford.png' },
  { id: 'hyundai', file: 'assets/logos/hyundai_logo.png', dest: 'logos/hyundai.png' },
  { id: 'byd', file: 'assets/logos/byd_logo.png', dest: 'logos/byd.png' }
];

// 2. Mapa de Modelos Top Colombia
const MODEL_ASSETS = [
  // Motos
  { id: 'akt_nkd125', file: 'assets/motos/akt/NKD.png', dest: 'models/akt_nkd125.png' },
  { id: 'akt_cr4_150', file: 'assets/motos/akt/CR4_150.png', dest: 'models/akt_cr4_150.png' },
  { id: 'akt_dynamic', file: 'assets/motos/akt/dinamicpro.png', dest: 'models/akt_dynamic.png' },
  { id: 'bajaj_boxer_ct100', file: 'assets/motos/bajaj/boxer-ct100.png', dest: 'models/bajaj_boxer_ct100.png' },
  { id: 'bajaj_pulsar_ns200', file: 'assets/motos/bajaj/pulsar-ns200-fi-abs.png', dest: 'models/bajaj_pulsar_ns200.png' },
  { id: 'bajaj_pulsar_n160', file: 'assets/motos/bajaj/pulsar-n160.png', dest: 'models/bajaj_pulsar_n160.png' },
  { id: 'bajaj_pulsar_n250', file: 'assets/motos/bajaj/Pulsar-N250.png', dest: 'models/bajaj_pulsar_n250.png' },
  { id: 'bajaj_dominar_400', file: 'assets/motos/bajaj/Dominar-400-touring.png', dest: 'models/bajaj_dominar_400.png' },
  { id: 'yamaha_nmax', file: 'assets/motos/yamaha/nmax.png', dest: 'models/yamaha_nmax.png' },
  { id: 'yamaha_crypton', file: 'assets/motos/yamaha/cripton.png', dest: 'models/yamaha_crypton.png' },
  { id: 'yamaha_fz25', file: 'assets/motos/yamaha/fz25.png', dest: 'models/yamaha_fz25.png' },
  { id: 'yamaha_xtz150', file: 'assets/motos/yamaha/XTZ150.png', dest: 'models/yamaha_xtz150.png' },
  { id: 'yamaha_mt15', file: 'assets/motos/yamaha/mt15.png', dest: 'models/yamaha_mt15.png' },
  { id: 'suzuki_gixxer150', file: 'assets/motos/suzuki/gixxer150.png', dest: 'models/suzuki_gixxer150.png' },
  { id: 'suzuki_gn125', file: 'assets/motos/suzuki/GN125.png', dest: 'models/suzuki_gn125.png' },
  { id: 'suzuki_dr150', file: 'assets/motos/suzuki/DR.png', dest: 'models/suzuki_dr150.png' },
  { id: 'tvs_raider125', file: 'assets/motos/tvs/raider125.png', dest: 'models/tvs_raider125.png' },
  { id: 'tvs_apache160', file: 'assets/motos/tvs/apache160.png', dest: 'models/tvs_apache160.png' },
  { id: 'honda_cb125f', file: 'assets/motos/honda/cb125f.png', dest: 'models/honda_cb125f.png' },
  { id: 'honda_cb160f', file: 'assets/motos/honda/cb160f.png', dest: 'models/honda_cb160f.png' },
  { id: 'hero_eco_deluxe', file: 'assets/motos/hero/Eco_Deluxe.png', dest: 'models/hero_eco_deluxe.png' },
  { id: 'hero_splendor', file: 'assets/motos/hero/Splendor-Xpro.png', dest: 'models/hero_splendor.png' },
  { id: 'hero_xpulse200', file: 'assets/motos/hero/Xpulse2004v.png', dest: 'models/hero_xpulse200.png' },
  { id: 'ktm_duke200', file: 'assets/motos/ktm/DUKE-200.png', dest: 'models/ktm_duke200.png' },
  { id: 'ktm_duke390', file: 'assets/motos/ktm/KTM-390-DUKE.png', dest: 'models/ktm_duke390.png' },

  // Carros
  { id: 'renault_duster', file: 'assets/carros/renault/duster.png', dest: 'models/renault_duster.png' },
  { id: 'renault_sandero', file: 'assets/carros/renault/sandero.png', dest: 'models/renault_sandero.png' },
  { id: 'renault_kwid', file: 'assets/carros/renault/kwid.png', dest: 'models/renault_kwid.png' },
  { id: 'chevrolet_onix', file: 'assets/carros/chevrolet/onix-turbo-sedan.png', dest: 'models/chevrolet_onix.png' },
  { id: 'chevrolet_tracker', file: 'assets/carros/chevrolet/tracker-RS.png', dest: 'models/chevrolet_tracker.png' },
  { id: 'chevrolet_spark', file: 'assets/carros/chevrolet/SparkEUV.png', dest: 'models/chevrolet_spark.png' },
  { id: 'chevrolet_captiva', file: 'assets/carros/chevrolet/CAPTIVA_TURBO-XL.png', dest: 'models/chevrolet_captiva.png' },
  { id: 'kia_picanto', file: 'assets/carros/kia/picanto.png', dest: 'models/kia_picanto.png' },
  { id: 'mazda_2_hb', file: 'assets/carros/mazda/mazda2.png', dest: 'models/mazda_2_hb.png' },
  { id: 'mazda_2_sedan', file: 'assets/carros/mazda/mazda2sedan.png', dest: 'models/mazda_2_sedan.png' },
  { id: 'mazda_3', file: 'assets/carros/mazda/mazda3.png', dest: 'models/mazda_3.png' },
  { id: 'toyota_corolla_cross', file: 'assets/carros/toyota/corolla_cross.png', dest: 'models/toyota_corolla_cross.png' },
  { id: 'toyota_hilux', file: 'assets/carros/toyota/hilux.png', dest: 'models/toyota_hilux.png' },
  { id: 'toyota_fortuner', file: 'assets/carros/toyota/fortuner.png', dest: 'models/toyota_fortuner.png' },
  { id: 'toyota_corolla', file: 'assets/carros/toyota/corolla.png', dest: 'models/toyota_corolla.png' },
  { id: 'toyota_yaris', file: 'assets/carros/toyota/yaris.png', dest: 'models/toyota_yaris.png' },
  { id: 'toyota_prado', file: 'assets/carros/toyota/landcruiser300.png', dest: 'models/toyota_prado.png' }
];

async function uploadFile(localPath, remotePath) {
  if (!fs.existsSync(localPath)) {
    console.error(`[OMITIDO] No existe archivo local: ${localPath}`);
    return null;
  }

  const fileBuffer = fs.readFileSync(localPath);
  const ext = path.extname(localPath).toLowerCase();
  const contentType = ext === '.svg' ? 'image/svg+xml' : 'image/png';

  if (IS_DRY_RUN) {
    console.log(`[DRY-RUN] Subiendo ${localPath} (${fileBuffer.length} bytes) -> ${BUCKET}/${remotePath}`);
    return `${SUPABASE_URL || 'https://tu-proyecto.supabase.co'}/storage/v1/object/public/${BUCKET}/${remotePath}`;
  }

  const uploadUrl = `${SUPABASE_URL}/storage/v1/object/${BUCKET}/${remotePath}`;
  const res = await fetch(uploadUrl, {
    method: 'POST',
    headers: {
      'apikey': SUPABASE_KEY,
      'Authorization': `Bearer ${SUPABASE_KEY}`,
      'Content-Type': contentType,
      'x-upsert': 'true'
    },
    body: fileBuffer
  });

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Fallo al subir ${remotePath}: [${res.status}] ${err}`);
  }

  const publicUrl = `${SUPABASE_URL}/storage/v1/object/public/${BUCKET}/${remotePath}`;
  console.log(`\x1b[32m✔ Subido con éxito:\x1b[0m ${publicUrl}`);
  return publicUrl;
}

async function main() {
  console.log('\x1b[36m============================================================\x1b[0m');
  console.log('\x1b[36m  MY AUTO GUIDE • SINCRONIZADOR DE ASSETS A SUPABASE STORAGE\x1b[0m');
  console.log('\x1b[36m============================================================\x1b[0m');
  console.log(`Destino: Bucket '${BUCKET}' en ${SUPABASE_URL || 'DRY-RUN'}\n`);

  console.log('📌 1. Subiendo Logos de Marcas Oficiales...');
  for (const b of BRAND_LOGOS) {
    await uploadFile(b.file, b.dest);
  }

  console.log('\n📌 2. Subiendo Fotos de Modelos Transparentes Top Colombia...');
  for (const m of MODEL_ASSETS) {
    await uploadFile(m.file, m.dest);
  }

  console.log('\n\x1b[32m✔ ¡Sincronización completada con éxito!\x1b[0m');
}

main().catch(console.error);
