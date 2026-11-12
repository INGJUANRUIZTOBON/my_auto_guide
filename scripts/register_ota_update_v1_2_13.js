const https = require('https');

const SUPABASE_URL = 'https://iqdobggghorpuepuquhb.supabase.co';
const ANON_KEY = 'sb_publishable_4ldD5RfYCB6fTFle_9rgAQ_JFv_fNsl';

async function registerVersion() {
  const versionData = {
    version_code: 31,
    version_name: '1.2.13',
    zip_url: 'https://github.com/INGJUANRUIZTOBON/my_auto_guide/releases/download/1.1.0/app-release.apk',
    release_notes: '• Catálogo Motos Motai HD: 62 nuevos modelos de motocicletas con siluetas transparentes de alta resolución sin fondo.\n• 4 Nuevas Marcas Oficiales de Motos: Benelli, Kymco, SYM y Fratelli con logos vectorizados HD.\n• Catálogo Expandido de Motos: Nuevas líneas icónicas de Victory (Combat, MRX, Nitro, One ST), TVS (Sport 110, Neo), Hero (Hunk 160 4V, XPulse 200, Eco 100), AKT (AK200DS, Sc-r), Honda, Bajaj y Royal Enfield (Hntr 350).\n• Cero Peso Extra en el APK: 100% de siluetas de motos servidas dinámicamente desde el CDN de Supabase Storage.\n• Resiliencia Offline Completa: Mapeo de logos y colores oficiales para todas las marcas nuevas sin iconos rotos.',
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
      console.log('Register Version 31 Status:', res.statusCode);
      console.log('Response:', body);
    });
  });

  req.on('error', (err) => console.error('Error registering version:', err));
  req.write(payload);
  req.end();
}

registerVersion();
