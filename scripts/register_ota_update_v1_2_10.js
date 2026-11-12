const https = require('https');

const SUPABASE_URL = 'https://iqdobggghorpuepuquhb.supabase.co';
const SERVICE_KEY = 'sb_secret_3g9hjQsbxUFhwvsx-32qjQ_fi-l7MoD';

async function registerVersion() {
  const versionData = {
    version_code: 27,
    version_name: '1.2.10',
    zip_url: 'https://github.com/INGJUANRUIZTOBON/my_auto_guide/releases/download/1.1.0/app-release.apk',
    release_notes: '• Notificación GPS estrictamente bajo demanda: La notificación fija "Recorrido en Progreso" SOLO aparece cuando inicias activamente un viaje en Rutas/Navegación. Nunca más visible en reposo, en el garaje o al abrir la app.\n• Auto-destrucción y limpieza inmediata: Al tocar "Finalizar Recorrido" o salir del mapa, el servicio se detiene y la notificación desaparece al instante de la barra de estado.\n• Máximo ahorro de batería: El chip GPS no consume energía cuando no estás en un viaje activo.',
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
      console.log('Register Version 27 Status:', res.statusCode);
      console.log('Response:', body);
    });
  });

  req.on('error', (err) => console.error('Error registering version:', err));
  req.write(payload);
  req.end();
}

registerVersion();
