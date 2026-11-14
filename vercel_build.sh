#!/bin/bash
set -e

echo "🚀 Iniciando configuración de Flutter SDK en Vercel..."

# Instalar Flutter SDK si no existe en el contenedor
if [ ! -d "flutter" ]; then
  echo "📥 Clonando Flutter SDK (versión estable)..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 flutter
else
  echo "🔄 Actualizando Flutter SDK existente..."
  cd flutter && git pull && cd ..
fi

# Agregar Flutter al PATH
export PATH="$PATH:$PWD/flutter/bin"

echo "🔧 Versión de Flutter instalada:"
flutter --version

echo "📦 Habilitando compilación Web..."
flutter config --enable-web

echo "📥 Descargando dependencias..."
flutter pub get

echo "🔑 Configurando .env para empaquetado de assets..."
if [ ! -f ".env" ]; then
  touch .env
  echo "SUPABASE_URL=${SUPABASE_URL:-https://iqdobggghorpuepuquhb.supabase.co}" >> .env
  echo "SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY:-sb_publishable_4ldD5RfYCB6fTFle_9rgAQ_JFv_fNsl}" >> .env
  if [ -n "$GEMINI_API_KEY" ]; then echo "GEMINI_API_KEY=$GEMINI_API_KEY" >> .env; fi
  if [ -n "$CARTO_API_KEY" ]; then echo "CARTO_API_KEY=$CARTO_API_KEY" >> .env; fi
  echo "✅ Archivo .env preparado para la compilación."
fi

echo "⚡ Compilando My Auto Guide para la Web (Release)..."
flutter build web --release --no-wasm-dry-run

echo "✅ Compilación Web exitosa en build/web"
