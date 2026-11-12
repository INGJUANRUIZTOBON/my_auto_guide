const fs = require('fs');
const path = require('path');

const SUPABASE_URL = 'https://iqdobggghorpuepuquhb.supabase.co';
const SUPABASE_KEY = 'sb_secret_3g9hjQsbxUFhwvsx-32qjQ_fi-l7MoD';
const BUCKET = 'catalog-assets';

async function uploadFile(filePath) {
  const remotePath = filePath.replace(/\\/g, '/');
  if (!fs.existsSync(filePath)) {
    console.error(`File does not exist: ${filePath}`);
    return 404;
  }
  const fileBuf = fs.readFileSync(filePath);
  const uploadUrl = `${SUPABASE_URL}/storage/v1/object/${BUCKET}/${remotePath}`;
  
  const res = await fetch(uploadUrl, {
    method: 'POST',
    headers: {
      'apikey': SUPABASE_KEY,
      'Authorization': `Bearer ${SUPABASE_KEY}`,
      'Content-Type': 'image/png',
      'x-upsert': 'true'
    },
    body: fileBuf
  });
  return res.status;
}

async function main() {
  const logos = [
    'assets/logos/changan.png',
    'assets/logos/chery.png',
    'assets/logos/deepal.png',
    'assets/logos/haval.png',
    'assets/logos/honda_logo.png',
    'assets/logos/jmc.png',
    'assets/logos/opel.png'
  ];

  console.log(`Subiendo ${logos.length} logos de nuevas marcas...`);
  for (const logo of logos) {
    const st = await uploadFile(logo);
    console.log(`Logo: ${logo} -> Status: ${st}`);
  }

  const autonal = JSON.parse(fs.readFileSync('scripts/autonal_processed_final.json', 'utf8'));
  console.log(`Subiendo ${autonal.length} imágenes de vehículos Autonal...`);
  let successCount = 0;
  for (let i = 0; i < autonal.length; i++) {
    const item = autonal[i];
    const st = await uploadFile(item.asset_path);
    if (st === 200 || st === 201) {
      successCount++;
    } else {
      console.warn(`[WARN] ${item.asset_path} -> HTTP ${st}`);
    }
  }
  console.log(`Subida completada: ${successCount}/${autonal.length} imágenes subidas correctamente a Supabase Storage.`);
}

main().catch(console.error);
