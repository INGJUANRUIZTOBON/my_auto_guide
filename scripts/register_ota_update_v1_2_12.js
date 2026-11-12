const https = require('https');

const SUPABASE_URL = 'https://iqdobggghorpuepuquhb.supabase.co';
const ANON_KEY = 'sb_publishable_4ldD5RfYCB6fTFle_9rgAQ_JFv_fNsl';

async function registerVersion() {
  const versionData = {
    version_code: 30,
    version_name: '1.2.12',
    zip_url: 'https://github.com/INGJUANRUIZTOBON/my_auto_guide/releases/download/1.1.0/app-release.apk',
    release_notes: '• Catálogo 100% Remoto en CDN Supabase: 32 marcas y 87 modelos nuevos con siluetas transparentes HD servidas directamente desde la nube.\n• Nuevas Marcas y Modelos: Deepal (S07), Audi (Q5, Q3), BMW (X2, X5), Chery (Tiggo 4, eQ7), Haval (H6), Jeep (Wrangler), Suzuki (Baleno, Fronx), Tesla (Model Y), VW (Golf), Changan, JMC, Opel y más.\n• Instalador Ultraligero: Cero imágenes pesadas embebidas en el APK, permitiendo descargas e instalaciones inmediatas.\n• Escaneo Láser Holográfico: Carga cinemática fluida a 60-120 FPS con caché inteligente en memoria sin consumir datos adicionales tras la primera vista.\n• GPS Bajo Demanda: Máximo ahorro de batería con servicio satelital activo exclusivamente durante recorridos.',
    is_mandatory: true,
    min_supported_version: 1
  };

  const payload = JSON.stringify(versionData);

  const req = https.request(`${SUPABASE_URL}/rest/v1/app_versions?on_conflict=version_code`, {
    method: 'POST',
    headers: {
      'apikey': ANON_KEY,
      'Authorization': `Bearer ${ANON_KEY}`,
      'Content-Type': 'application/json',
      'Prefer': 'resolution=merge-duplicates,return=representation'
    }
  }, (res) => {
    let body = '';
    res.on('data', chunk => body += chunk);
    res.on('end', () => {
      console.log('Register Version 30 Status:', res.statusCode);
      console.log('Response:', body);
    });
  });

  req.on('error', (err) => console.error('Error registering version:', err));
  req.write(payload);
  req.end();
}

registerVersion();
