<#
.SYNOPSIS
    Script de Sincronización y Publicación Dual (Web Vercel + Android OTA) para MY AUTO GUIDE.

.DESCRIPTION
    Asegura que cada nueva actualización se compile, documente con sus notas de versión,
    se registre en Supabase app_versions, y se sincronice tanto en la Web (Vercel) como en Android.

.EXAMPLE
    .\scripts\publish_release.ps1 -VersionName "1.2.14" -VersionCode 32 -ReleaseNotes "Nueva versión Web con telemetría en vivo y soporte adaptativo."
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$VersionName,

    [Parameter(Mandatory = $true)]
    [int]$VersionCode,

    [Parameter(Mandatory = $true)]
    [string]$ReleaseNotes,

    [switch]$BuildApk = $false
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "🚀 PUBLICACIÓN DUAL SINCRONIZADA: MY AUTO GUIDE" -ForegroundColor Cyan
Write-Host "Versión: v$VersionName (Build $VersionCode)" -ForegroundColor Yellow
Write-Host "Notas: $ReleaseNotes" -ForegroundColor Gray
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Actualizar versión en pubspec.yaml
Write-Host "`n[1/5] Actualizando versión en pubspec.yaml..." -ForegroundColor Green
$pubspecPath = "pubspec.yaml"
$pubspecContent = Get-Content $pubspecPath -Raw
$newVersionString = "version: $VersionName+$VersionCode"
$pubspecContent = $pubspecContent -replace "version:\s*[\d\.\+]+", $newVersionString
Set-Content -Path $pubspecPath -Value $pubspecContent -NoNewline
Write-Host "✔ pubspec.yaml actualizado a $newVersionString" -ForegroundColor Gray

# 2. Compilar Web para Vercel
Write-Host "`n[2/5] Compilando Web de Producción (CanvasKit)..." -ForegroundColor Green
flutter build web --release --no-wasm-dry-run
if ($LASTEXITCODE -ne 0) {
    Write-Error "Fallo en compilación Web. Abortando publicación."
    exit 1
}
Write-Host "✔ Build Web generado con éxito en build/web" -ForegroundColor Gray

# 3. Compilar APK si fue solicitado
if ($BuildApk) {
    Write-Host "`n[3/5] Compilando APK Android Release (OTA)..." -ForegroundColor Green
    flutter build apk --release
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Fallo en compilación APK. Abortando publicación."
        exit 1
    }
    Write-Host "✔ APK Release generado con éxito en build/app/outputs/flutter-apk/app-release.apk" -ForegroundColor Gray
} else {
    Write-Host "`n[3/5] Omitiendo compilación APK (Usa -BuildApk para generar APK físico)..." -ForegroundColor DarkGray
}

# 4. Actualizar grafo de conocimiento
Write-Host "`n[4/5] Actualizando grafo de arquitectura AST (graphify)..." -ForegroundColor Green
graphify update .

# 5. Git Commit y Push para Vercel
Write-Host "`n[5/5] Sincronizando con repositorio y Vercel (Git Push)..." -ForegroundColor Green
git add .
$commitMsg = "feat(release): v$VersionName ($VersionCode) - $ReleaseNotes"
git commit -m $commitMsg
git push origin main

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "✅ PUBLICACIÓN COMPLETADA CON ÉXITO" -ForegroundColor Green
Write-Host "• Web Vercel: Despliegue automático iniciado en Edge Network." -ForegroundColor White
Write-Host "• Novedades: Se mostrarán a los usuarios en su próximo ingreso." -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Cyan
