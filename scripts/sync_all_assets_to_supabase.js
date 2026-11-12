// =============================================================================
// sync_all_assets_to_supabase.js — MIGRACIÓN Y SINCRONIZACIÓN A SUPABASE STORAGE
// =============================================================================
// Sube todos los logos y vehículos transparentes de `assets/` al bucket público
// `catalog-assets` de Supabase Storage, y actualiza las tablas `catalogo_modelos`
// y `catalogo_marcas` con las URLs públicas HTTPS del CDN.
// =============================================================================

const fs = require('fs');
const path = require('path');

const SUPABASE_URL = 'https://iqdobggghorpuepuquhb.supabase.co';
const SUPABASE_KEY = 'sb_secret_3g9hjQsbxUFhwvsx-32qjQ_fi-l7MoD';
const BUCKET = 'catalog-assets';

function getFilesRecursively(dir) {
  let results = [];
  if (!fs.existsSync(dir)) return results;
  const list = fs.readdirSync(dir);
  for (const file of list) {
    const fullPath = path.join(dir, file);
    const stat = fs.statSync(fullPath);
    if (stat.isDirectory()) {
      results = results.concat(getFilesRecursively(fullPath));
    } else {
      const ext = path.extname(file).toLowerCase();
      if (['.png', '.jpg', '.jpeg', '.webp', '.svg'].includes(ext)) {
        // Normalizar a forward slash
        results.push(fullPath.replace(/\\/g, '/'));
      }
    }
  }
  return results;
}

async function uploadSingleFile(filePath) {
  const fileBuf = fs.readFileSync(filePath);
  const ext = path.extname(filePath).toLowerCase();
  let contentType = 'image/png';
  if (ext === '.svg') contentType = 'image/svg+xml';
  else if (ext === '.jpg' || ext === '.jpeg') contentType = 'image/jpeg';
  else if (ext === '.webp') contentType = 'image/webp';

  const remotePath = filePath.startsWith('assets/') ? filePath : `assets/${filePath}`;
  const uploadUrl = `${SUPABASE_URL}/storage/v1/object/${BUCKET}/${remotePath}`;

  const res = await fetch(uploadUrl, {
    method: 'POST',
    headers: {
      'apikey': SUPABASE_KEY,
      'Authorization': `Bearer ${SUPABASE_KEY}`,
      'Content-Type': contentType,
      'x-upsert': 'true'
    },
    body: fileBuf
  });

  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`[${res.status}] Error subiendo ${filePath}: ${errText}`);
  }

  const publicUrl = `${SUPABASE_URL}/storage/v1/object/public/${BUCKET}/${remotePath}`;
  return { filePath, remotePath, publicUrl };
}

async function uploadInBatches(files, batchSize = 6) {
  const results = [];
  for (let i = 0; i < files.length; i += batchSize) {
    const batch = files.slice(i, i + batchSize);
    const promises = batch.map(f =>
      uploadSingleFile(f)
        .then(res => {
          process.stdout.write(`✔ [${results.length + 1}/${files.length}] ${f}\n`);
          return res;
        })
        .catch(err => {
          console.error(`❌ Fallo en ${f}:`, err.message);
          return null;
        })
    );
    const batchResults = await Promise.all(promises);
    for (const r of batchResults) {
      if (r) results.push(r);
    }
  }
  return results;
}

async function updateSupabaseCatalogs(uploadedMap) {
  console.log('\n📌 Actualizando tabla catalogo_modelos en Supabase con URLs públicas...');

  // 1. Obtener todos los modelos actuales
  const resModels = await fetch(`${SUPABASE_URL}/rest/v1/catalogo_modelos?select=id,marca_id,modelo,imagen_url`, {
    headers: {
      'apikey': SUPABASE_KEY,
      'Authorization': `Bearer ${SUPABASE_KEY}`
    }
  });

  const models = await resModels.json();
  let updatedCount = 0;

  for (const m of models) {
    const currentImg = m.imagen_url || '';
    // Normalizar ruta
    const cleanImg = currentImg.replace(/^https?:\/\/[^\/]+\/storage\/v1\/object\/public\/[^\/]+\//, '');
    const publicUrl = `${SUPABASE_URL}/storage/v1/object/public/${BUCKET}/${cleanImg}`;

    if (currentImg !== publicUrl) {
      const patchRes = await fetch(`${SUPABASE_URL}/rest/v1/catalogo_modelos?id=eq.${m.id}`, {
        method: 'PATCH',
        headers: {
          'apikey': SUPABASE_KEY,
          'Authorization': `Bearer ${SUPABASE_KEY}`,
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal'
        },
        body: JSON.stringify({ imagen_url: publicUrl })
      });

      if (patchRes.ok) {
        updatedCount++;
      } else {
        console.error(`Error actualizando modelo ${m.modelo}:`, await patchRes.text());
      }
    }
  }
  console.log(`✔ ${updatedCount} modelos actualizados con su URL pública de CDN en Supabase.`);

  // 2. Obtener marcas actuales
  console.log('\n📌 Actualizando tabla catalogo_marcas en Supabase con URLs de logos...');
  const resBrands = await fetch(`${SUPABASE_URL}/rest/v1/catalogo_marcas?select=id,nombre,logo_url`, {
    headers: {
      'apikey': SUPABASE_KEY,
      'Authorization': `Bearer ${SUPABASE_KEY}`
    }
  });

  const brands = await resBrands.json();
  let updatedBrands = 0;

  for (const b of brands) {
    const currentLogo = b.logo_url || '';
    const cleanLogo = currentLogo.replace(/^https?:\/\/[^\/]+\/storage\/v1\/object\/public\/[^\/]+\//, '');
    const publicUrl = `${SUPABASE_URL}/storage/v1/object/public/${BUCKET}/${cleanLogo}`;

    if (currentLogo !== publicUrl) {
      const patchRes = await fetch(`${SUPABASE_URL}/rest/v1/catalogo_marcas?id=eq.${b.id}`, {
        method: 'PATCH',
        headers: {
          'apikey': SUPABASE_KEY,
          'Authorization': `Bearer ${SUPABASE_KEY}`,
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal'
        },
        body: JSON.stringify({ logo_url: publicUrl })
      });

      if (patchRes.ok) {
        updatedBrands++;
      }
    }
  }
  console.log(`✔ ${updatedBrands} marcas actualizadas con logos en Supabase.`);
}

async function main() {
  console.log('============================================================');
  console.log('🚀 SUBIENDO ASSETS VEHICULARES AL STORAGE DE SUPABASE');
  console.log(`Destino: Bucket '${BUCKET}' en ${SUPABASE_URL}`);
  console.log('============================================================\n');

  const dirs = [
    'assets/motos',
    'assets/carros',
    'assets/logos'
  ];

  let allFiles = [];
  for (const d of dirs) {
    allFiles = allFiles.concat(getFilesRecursively(d));
  }

  console.log(`Archivos encontrados para subir: ${allFiles.length}`);
  const uploaded = await uploadInBatches(allFiles, 6);
  console.log(`\n✔ ¡${uploaded.length} archivos subidos exitosamente a Supabase Storage!`);

  await updateSupabaseCatalogs(uploaded);
  console.log('\n🎉 ¡SINCRONIZACIÓN TOTAL FINALIZADA CON ÉXITO!');
}

main().catch(err => {
  console.error('ERROR FATAL:', err);
  process.exit(1);
});
