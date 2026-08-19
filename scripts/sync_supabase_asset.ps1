# Copia supabase.define.json → assets/supabase_runtime.json para empaquetar credenciales en el APK
# cuando --dart-define-from-file no se aplica bien. Ejecutar desde la raíz del proyecto Flutter.
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..
Copy-Item -LiteralPath "supabase.define.json" -Destination "assets\supabase_runtime.json" -Force
Write-Host "OK: assets\supabase_runtime.json actualizado desde supabase.define.json"
