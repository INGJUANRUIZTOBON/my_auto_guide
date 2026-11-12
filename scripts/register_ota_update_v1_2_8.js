const fs = require('fs');
const path = require('path');
const https = require('https');

const SUPABASE_URL = 'https://iqdobggghorpuepuquhb.supabase.co';
const SERVICE_KEY = 'sb_secret_3g9hjQsbxUFhwvsx-32qjQ_fi-l7MoD';

async function registerVersion() {
  const versionData = {
    version_code: 25,
    version_name: '1.2.8',
    zip_url: 'https://github.com/INGJUANRUIZTOBON/my_auto_guide/releases/download/1.1.0/app-release.apk',
    release_notes: '• Logos oficiales de marcas corregidos: visualización transparente HD en la barra de selección tanto de carros como de motos.\n• 27 nuevos modelos colombianos integrados al catálogo Cloud (127 modelos en total: BWS 125, Aerox 155, Seltos, CR4 150/200, Gixxer 250, Montana, Silverado, etc.).\n• Optimización de peso de la APK y CDN Cloud: Las imágenes se cargan dinámicamente desde Supabase Storage CDN con caché local sin aumentar el tamaño de descarga.\n• Resiliencia y auto-actualización OTA mejorada con GitHub Releases y Supabase.',
    is_mandatory: true,
    min_supported_version: 1
  };

  const payload = JSON.stringify(versionData);

  const req = https.request(`${SUPABASE_URL}/rest/v1/app_versions?on_conflict=version_code`, {
    method: 'POST',
    headers: {
      'apikey': SERVICE_KEY,
      'Authorization': `Bearer ${SERVICE_KEY}`,
      'Content-Type': 'application/json',
      'Prefer': 'resolution=merge-duplicates,return=representation'
    }
  }, (res) => {
    let body = '';
    res.on('data', chunk => body += chunk);
    res.on('end', () => {
      console.log('Register Version Status:', res.statusCode);
      console.log('Response:', body);
    });
  });

  req.on('error', (err) => console.error('Error registering version:', err));
  req.write(payload);
  req.end();
}

registerVersion();
