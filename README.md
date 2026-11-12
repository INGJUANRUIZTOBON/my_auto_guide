# 🏎️ MY AUTO GUIDE (v1.2.12)
> **Tu vehículo, bajo control inteligente.**  
> Ecosistema integral de telemetría automotriz, navegación pro con GPS Kalman, catálogo cloud de Colombia, diagnóstico OBD2 y automatización RUNT.

[![Flutter](https://img.shields.io/badge/Flutter-3.27.0-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend%20%26%20CDN-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![Android](https://img.shields.io/badge/Android-APK%20v1.2.12-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://github.com/INGJUANRUIZTOBON/my_auto_guide/releases/download/1.1.0/app-release.apk)
[![License](https://img.shields.io/badge/Licencia-Privada%20%2F%20Comercial-FF6D00?style=for-the-badge)](LICENSE)

---

## 📥 Descarga Directa de la Aplicación

Puedes descargar el instalador oficial de Android directamente desde el repositorio:

[![Descargar APK](https://img.shields.io/badge/Descargar%20APK%20Oficial-v1.2.12%20(Build%2030)-00E5FF?style=for-the-badge&logo=android&logoColor=black)](https://github.com/INGJUANRUIZTOBON/my_auto_guide/releases/download/1.1.0/app-release.apk)

- 📦 **Enlace directo de descarga**: [app-release.apk (GitHub Releases)](https://github.com/INGJUANRUIZTOBON/my_auto_guide/releases/download/1.1.0/app-release.apk)
- 🚀 **Auto-Actualización OTA**: La app cuenta con motor Over-The-Air impulsado por Supabase. Al instalar esta versión, cualquier actualización futura se descargará e instalará automáticamente en tu teléfono.

---

## 🌟 Novedades de la Versión 1.2.12

### 1. 🚗 Catálogo Nacional Masivo: Autoland + Autonal Colombia (32 Marcas y 87 Modelos)
- **7 Nuevas Marcas Oficiales Agregadas**: Changan, Chery, Deepal, Haval, Honda (Línea Carros), JMC y Opel, con sus respectivos logos vectoriales HD y paleta de color oficial.
- **35 Nuevos Modelos Exclusivos de Autonal**: Sin duplicar ninguno de los existentes (BYD Seagull, BYD Yuan Plus, Chery Tiggo 4, Suzuki Baleno, Suzuki Fronx, VW Golf, VW Voyage, Audi Q5, BMW X2, Ford Fiesta, Jeep Compass, etc.).
- **Procesamiento Neuronal Transparente**: 100% de los vehículos con recorte limpio de fondo (`rembg` / `u2netp`) y márgenes balanceados para el garaje oscuro.
- **Resolución de Error 42P10 en Supabase**: Script de migración con deduplicación y creación de índice único `(marca_id, tipo, linea)` para inserciones y actualizaciones idempotentes libres de conflicto.

### 2. 🌌 Animación Cinemática de Carga — Escaneo Láser Holográfico (60-120 FPS)
- **Motor GPU nativo (`CustomPainter`)**: Efecto túnel de viento aerodinámico que recorre la silueta del vehículo con un haz láser neón vertical de izquierda a derecha.
- **Siluetas inteligentes adaptativas**: Diferenciación vectorial precisa entre carrocerías de automóvil y motocicleta.
- **Entrada natural (Micro-escala 0.96 → 1.0)**: Cross-fade suave de 250ms y respuesta háptica física (*Taptic Engine*) al completar la descarga.
- **Resiliencia Offline**: Detección de pérdida de cobertura 4G con timeout automático a los 5s y botón de reintento.

### 3. 📡 GPS Bajo Demanda y Navegación Pro Colombia (Estilo Waze)
- **Foreground Service estrictamente bajo demanda**: La notificación fija *"Recorrido en Progreso"* y el rastreador de fondo **solo se encienden cuando presionas Iniciar Ruta o Recorrido Libre**, auto-destruyéndose inmediatamente al finalizar o salir del mapa.
- **Filtro de Kalman Cinemático**: Suavizado continuo de coordenadas eliminando rebotes de antena y saltos erráticos a 60 FPS.
- **Grabación con pantalla suspendida**: Mantiene la telemetría, velocidad y odometría viva en el bolsillo sin que Android duerma el chip GPS.
- **Servicios viales de Colombia**: Radares de fotomultas, peajes estimados, precios de combustible actualizados, reportes comunitarios y voz manos libres (`flutter_tts`).

### 3. ☁️ Catálogo Cloud de Marcas y Modelos de Colombia
- **127 modelos y 22 marcas comerciales**: Carga dinámica bajo demanda desde Supabase Storage CDN (sin inflar el APK).
- **Especificaciones técnicas completas**: Cilindraje (cc), tipo de combustible, capacidad de tanque (galones), potencia (HP) y grado de aceite recomendado.
- **Logos oficiales en alta definición**: Transparencias nativas RGBA para todas las marcas (carros y motos).

### 4. 📋 Integración y Extracción Automática RUNTPRO
- **Extractor inteligente en 3 etapas**: Conexión con el portal oficial del RUNT para consultar SOAT, Tecnomecánica (RTM), histórico de revisiones, gravámenes y multas en SIMIT.
- **Mi Licencia de Conducción**: Consulta ciudadana por cédula que detecta categorías vigentes (A2, B1, C1) y calcula el porcentaje de vida útil restante.

### 5. 🤖 Master Mechanic IA Multimodal (Gemini 2.5 Flash)
- Asistente de diagnóstico mecánico vehicular con soporte de visión artificial: adjunta fotos desde la cámara o galería y recibe asesoría técnica en tiempo real.

### 6. 🔌 Escáner OBD2 Pro & Modo HUD Parabrisas
- Conectividad Bluetooth ELM327 para lectura de telemetría en vivo, códigos de falla (DTC), Freeze Frame (Modo 02) y modo HUD invertido para reflejo en el parabrisas nocturno.

---

## 🏗️ Arquitectura del Sistema

```
┌────────────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER (UI)                         │
│   Obsidiana Cockpit  •  Liquid Glass UI  •  HUD  •  SmartVehicleImage  │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│                         PROVIDERS & LOGIC                              │
│   NavigationController  •  AuthProvider  •  TelemetryCalculator        │
│   GpsKalmanFilter       •  VehicleAILogic •  AppWidgetLogic            │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│                       SERVICES & BACKGROUND                            │
│   BackgroundNavService (Foreground) • AppUpdateService (OTA)           │
│   CloudCatalogService               • RuntVehicleService               │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│                         DATA LAYER & BACKEND                           │
│   Supabase PostgREST  •  Supabase Storage CDN  •  FlutterSecureStorage │
│   OpenStreetMap OSRM  •  Google Gemini 2.5 Flash                       │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Tecnologías y Librerías Principales

| Módulo | Tecnologías / Dependencias |
| :--- | :--- |
| **Framework Base** | Flutter 3.27.0 • Dart >= 3.3.0 |
| **Backend & Base de Datos** | Supabase Flutter SDK (`supabase_flutter: ^2.10.0`) |
| **Mapas & Geometría GPS** | `flutter_map: ^6.1.0`, `latlong2`, `geolocator: ^13.0.2` |
| **Procesamiento de Fondo** | `flutter_background_service: ^5.0.10`, `home_widget` |
| **Inteligencia Artificial** | `google_generative_ai: ^0.4.5` (Gemini 2.5 Flash) |
| **Seguridad Criptográfica** | `flutter_secure_storage: ^9.2.2`, `crypto: ^3.0.6` |
| **Diagnóstico OBD2** | `flutter_blue_plus: ^2.3.14` |
| **Documentos & Reportes** | `syncfusion_flutter_pdfviewer`, `pdf`, `printing` |

---

## 🚀 Puesta en Marcha Local (Desarrolladores)

### Requisitos Previos
- Flutter SDK 3.27.0 o superior
- Java Development Kit (JDK 17)
- Android SDK con soporte para API 34

### Instalación
```bash
# 1. Clonar el repositorio
git clone https://github.com/INGJUANRUIZTOBON/my_auto_guide.git
cd my_auto_guide

# 2. Instalar dependencias
flutter pub get

# 3. Configurar variables de entorno
# Copiar .env.example a .env y añadir tus credenciales de Supabase
cp .env.example .env

# 4. Ejecutar pruebas unitarias (144 tests)
flutter test --no-pub

# 5. Compilar APK Release
flutter build apk --release --no-pub
```

El binario de producción se generará en:  
`build/app/outputs/flutter-apk/app-release.apk`

---

## 🔒 Seguridad y Privacidad

- **Cifrado Hardware (Keystore / Keychain)**: Las credenciales de sesión y tokens de API se almacenan cifrados mediante hardware con `FlutterSecureStorage`.
- **Anonimización de Cédula**: Las cédulas de los propietarios se procesan con hashing criptográfico SHA-256 para prevenir fugas de datos en consultas externas.
- **Políticas RLS en Supabase**: Row Level Security activado en todas las tablas para garantizar que cada usuario acceda exclusivamente a sus propios vehículos y telemetría.

---

## 📄 Licencia

Desarrollado con altos estándares de ingeniería de software para el ecosistema automotor colombiano. Todos los derechos reservados.
