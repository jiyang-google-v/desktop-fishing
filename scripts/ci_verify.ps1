param([switch]$ExportOnly)
$ErrorActionPreference = 'Stop'
$godotExe = Join-Path $env:USERPROFILE 'godot/Godot_v4.6.1-stable_win64.exe'
function Invoke-GodotCheck([string[]]$GodotArgs) {
 $stamp = [guid]::NewGuid().ToString('N')
 $stdout = Join-Path $env:TEMP ("godot-" + $stamp + '.out')
 $stderr = Join-Path $env:TEMP ("godot-" + $stamp + '.err')
 $quoted = $GodotArgs | ForEach-Object { '"' + $_ + '"' }
 try {
  $process = Start-Process -FilePath $godotExe -ArgumentList $quoted -Wait -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
  $output = (Get-Content $stdout -Raw -ErrorAction SilentlyContinue) + (Get-Content $stderr -Raw -ErrorAction SilentlyContinue)
  Write-Host $output
  if ($process.ExitCode -ne 0 -or $output -match '(SCRIPT ERROR:|(?m)^ERROR:)') {
   throw "Godot validation failed ($($process.ExitCode))"
  }
 } finally {
  Remove-Item -LiteralPath $stdout,$stderr -Force -ErrorAction SilentlyContinue
 }
}
if ($ExportOnly) {
 New-Item -ItemType Directory -Force build/windows | Out-Null
 Invoke-GodotCheck -GodotArgs @('--headless','--export-release','Windows Desktop','build/windows/DesktopFishing.exe')
 Copy-Item README.md build/windows/README.md
 Copy-Item docs/WINDOWS_STAGE1_ACCEPTANCE.md build/windows/WINDOWS_STAGE1_ACCEPTANCE.md
} else {
 Invoke-GodotCheck -GodotArgs @('--headless','--editor','--import','--quit')
 Invoke-GodotCheck -GodotArgs @('--headless','--script','res://tests/run_tests.gd','--','--tests')
 Invoke-GodotCheck -GodotArgs @('--headless','--script','res://tests/run_windows_focus.gd','--','--tests')
 Invoke-GodotCheck -GodotArgs @('--headless','--quit-after','180','--','--tests','--ui-smoke')
}
