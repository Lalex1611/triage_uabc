# Ejecuta la app con las variables de Supabase (archivo JSON junto a pubspec).
Set-Location $PSScriptRoot\..
flutter run --dart-define-from-file=supabase.define.json
