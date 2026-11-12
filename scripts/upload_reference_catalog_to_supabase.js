// =============================================================================
// upload_reference_catalog_to_supabase.js
// =============================================================================
// Sube el compendio completo de fotos de referencia a Supabase Storage: 'referencias-modelos'
// =============================================================================

const fs = require('fs');
const path = require('path');

const SUPABASE_URL = 'https://iqdobggghorpuepuquhb.supabase.co';
const SUPABASE_KEY = 'sb_secret_3g9hjQsbxUFhwvsx-32qjQ_fi-l7MoD';
const BUCKET = 'referencias-modelos';
const MANIFEST_PATH = 'vehiculos_colombia_referencia/catalog_manifest.json';

async function uploadSingleFile(localPath, remotePath) {
  const fileBuf = fs.readFileSync(localPath);
  const uploadUrl = `${SUPABASE_URL}/storage/v1/object/${BUCKET}/${remotePath}`;

  const res = await fetch(uploadUrl, {
    method: 'POST',
    headers: {
      'apikey': SUPABASE_KEY,
      'Authorization': `Bearer ${SUPABASE_KEY}`,
      'Content-Type': 'image/jpeg',
      'x-upsert': 'true'
    },
    body: fileBuf
  });

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`[${res.status}] Error en ${remotePath}: ${err}`);
  }

  return `${SUPABASE_URL}/storage/v1/object/public/${BUCKET}/${remotePath}`;
}

async function main() {
  console.log('============================================================');
  console.log('☁ SUBIENDO FOTOS DE REFERENCIA A SUPABASE STORAGE');
  console.log(`Bucket destino: '${BUCKET}' en ${SUPABASE_URL}`);
  console.log('============================================================\n');

  if (!fs.existsSync(MANIFEST_PATH)) {
    console.error('No se encontró el archivo de manifiesto:', MANIFEST_PATH);
    process.exit(1);
  }

  const items = JSON.parse(fs.readFileSync(MANIFEST_PATH, 'utf8'));
  console.log(`Modelos a sincronizar: ${items.length}\n`);

  const batchSize = 6;
  let successCount = 0;

  for (let i = 0; i < items.length; i += batchSize) {
    const batch = items.slice(i, i + batchSize);
    const promises = batch.map(it =>
      uploadSingleFile(it.local_path, it.cloud_dest)
        .then(url => {
          successCount++;
          process.stdout.write(`✔ [${successCount}/${items.length}] ${it.cloud_dest}\n`);
          return url;
        })
        .catch(err => {
          console.error(`❌ Falló ${it.cloud_dest}:`, err.message);
          return null;
        })
    );
    await Promise.all(promises);
  }

  console.log(`\n🎉 ¡${successCount} fotografías de referencia respaldadas con éxito en Supabase Storage!`);
}

main().catch(console.error);
