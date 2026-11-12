const https = require('https');

const SUPABASE_URL = 'https://iqdobggghorpuepuquhb.supabase.co';
const SERVICE_KEY = 'sb_secret_3g9hjQsbxUFhwvsx-32qjQ_fi-l7MoD';

async function registerVersion() {
  const versionData = {
    version_code: 26,
    version_name: '1.2.9',
    zip_url: 'https://github.com/INGJUANRUIZTOBON/my_auto_guide/releases/download/1.1.0/app-release.apk',
    release_notes: '• Nueva Animación de Carga Cinemática: Escaneo Láser Holográfico a 60-120 FPS sobre siluetas aerodinámicas nativas de carro y moto con efecto túnel de viento.\n• Micro-Shimmer Adaptativo: Carga fluida y liviana para logos de marcas y miniaturas sin sobrecargar la GPU.\n• Transición de Revelado Suave: Cross-fade de 250ms con micro-escala natural y respuesta háptica sutil al finalizar la descarga.\n• Resiliencia Offline: Timeout inteligente de 5s con opción de reintento si estás en carretera sin cobertura 4G.\n• Cero impacto en batería: Renderizado 100% vectorial acelerado por hardware sin rebuilds innecesarios.',
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
      console.log('Register Version 26 Status:', res.statusCode);
      console.log('Response:', body);
    });
  });

  req.on('error', (err) => console.error('Error registering version:', err));
  req.write(payload);
  req.end();
}

registerVersion();
