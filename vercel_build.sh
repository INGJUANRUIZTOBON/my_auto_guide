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

echo "⚡ Compilando My Auto Guide para la Web (Release)..."
flutter build web --release

echo "✅ Compilación Web exitosa en build/web"
