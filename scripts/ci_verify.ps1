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
 Copy-Item docs/CATCH_ZOOM_QA.md build/windows/CATCH_ZOOM_QA.md
 Copy-Item docs/qa/catch-zoom build/windows/catch-zoom-preview -Recurse
 Copy-Item docs/FLOATING_COMPLETE_QA.md build/windows/FLOATING_COMPLETE_QA.md
 Copy-Item docs/qa/floating-complete build/windows/floating-complete-preview -Recurse
 Copy-Item docs/POMODORO_SPEC.md build/windows/POMODORO_SPEC.md
 Copy-Item docs/POMODORO_QA.md build/windows/POMODORO_QA.md
 Copy-Item docs/REFERENCE_SCENE_QA.md build/windows/REFERENCE_SCENE_QA.md
 Copy-Item docs/POMODORO_CARD_A_QA.md build/windows/POMODORO_CARD_A_QA.md
 Copy-Item docs/WINDOW_FRAME_QA.md build/windows/WINDOW_FRAME_QA.md
 Copy-Item docs/qa/window-frame build/windows/window-frame-preview -Recurse
 Copy-Item docs/FLOATING_CONTROLS_QA.md build/windows/FLOATING_CONTROLS_QA.md
 Copy-Item docs/qa/floating-controls build/windows/floating-controls-preview -Recurse
 Copy-Item docs/FLAT_BASE_QA.md build/windows/FLAT_BASE_QA.md
 Copy-Item docs/qa/flat-base build/windows/flat-base-preview -Recurse
 Copy-Item docs/qa/pomodoro-card build/windows/pomodoro-card-preview -Recurse
 Copy-Item docs/qa/pomodoro build/windows/pomodoro-preview -Recurse
 Copy-Item docs/WINDOWS_STAGE1_ACCEPTANCE.md build/windows/WINDOWS_STAGE1_ACCEPTANCE.md
 Copy-Item docs/STAGE2_ART_QA.md build/windows/STAGE2_ART_QA.md
 Copy-Item docs/STAGE3_ART_QA.md build/windows/STAGE3_ART_QA.md
 Copy-Item docs/qa/stage3 build/windows/stage3-preview -Recurse
 Copy-Item docs/STAGE4_ART_QA.md build/windows/STAGE4_ART_QA.md
 Copy-Item docs/qa/stage4 build/windows/stage4-preview -Recurse
 Copy-Item docs/FLOATING_ART_QA.md build/windows/FLOATING_ART_QA.md
 Copy-Item docs/qa/floating build/windows/floating-preview -Recurse
 Copy-Item docs/WINDOW_LAYOUT_QA.md build/windows/WINDOW_LAYOUT_QA.md
 Copy-Item docs/qa/layouts build/windows/layout-preview -Recurse
 Copy-Item docs/UI_FINISH_QA.md build/windows/UI_FINISH_QA.md
 if (Test-Path docs/qa/ui) { Copy-Item docs/qa/ui build/windows/ui-preview -Recurse }
} else {
 Invoke-GodotCheck -GodotArgs @('--headless','--editor','--import','--quit')
 Invoke-GodotCheck -GodotArgs @('--headless','--script','res://tests/run_tests.gd','--','--tests')
 Invoke-GodotCheck -GodotArgs @('--headless','--script','res://tests/pomodoro_tests.gd','--','--tests')
 Invoke-GodotCheck -GodotArgs @('--headless','--script','res://tests/pomodoro_ui_tests.gd','--','--tests')
 Invoke-GodotCheck -GodotArgs @('--headless','--script','res://tests/pomodoro_card_tests.gd','--','--tests')
 Invoke-GodotCheck -GodotArgs @('--audio-driver','Dummy','--rendering-method','gl_compatibility','--script','res://tests/pomodoro_card_capture.gd','--','--tests')
 Invoke-GodotCheck -GodotArgs @('--audio-driver','Dummy','--rendering-method','gl_compatibility','--script','res://tests/pomodoro_capture.gd','--','--tests')
 Invoke-GodotCheck -GodotArgs @('--headless','--script','res://tests/stage2_tests.gd','--','--tests')
 Invoke-GodotCheck -GodotArgs @('--headless','--script','res://tests/stage3_tests.gd','--','--tests')
 Invoke-GodotCheck -GodotArgs @('--headless','--script','res://tests/stage4_tests.gd','--','--tests')
 Invoke-GodotCheck -GodotArgs @('--headless','--script','res://tests/stage4_ui_tests.gd','--','--tests')
 Invoke-GodotCheck -GodotArgs @('--headless','--script','res://tests/floating_art_tests.gd','--','--tests')
 Invoke-GodotCheck -GodotArgs @('--headless','--script','res://tests/mode2_v5_tests.gd','--','--tests')
 Invoke-GodotCheck -GodotArgs @('--headless','--quit-after','300','--script','res://tests/floating_complete_tests.gd','--','--tests')
 Invoke-GodotCheck -GodotArgs @('--headless','--quit-after','300','--script','res://tests/catch_zoom_tests.gd','--','--tests')
 Invoke-GodotCheck -GodotArgs @('--audio-driver','Dummy','--rendering-method','gl_compatibility','--quit-after','600','--script','res://tests/catch_zoom_capture.gd','--','--tests')
 Invoke-GodotCheck -GodotArgs @('--audio-driver','Dummy','--rendering-method','gl_compatibility','--quit-after','600','--script','res://tests/floating_complete_capture.gd','--','--tests')
 Invoke-GodotCheck -GodotArgs @('--audio-driver','Dummy','--rendering-method','gl_compatibility','--quit-after','300','--script','res://tests/mode2_v5_capture.gd','--','--tests')
 Invoke-GodotCheck -GodotArgs @('--headless','--quit-after','300','--script','res://tests/window_frame_tests.gd','--','--tests')
 Invoke-GodotCheck -GodotArgs @('--audio-driver','Dummy','--rendering-method','gl_compatibility','--quit-after','300','--script','res://tests/window_frame_tests.gd','--','--tests')
 Invoke-GodotCheck -GodotArgs @('--audio-driver','Dummy','--rendering-method','gl_compatibility','--quit-after','300','--script','res://tests/window_frame_capture.gd','--','--tests')
 Invoke-GodotCheck -GodotArgs @('--headless','--script','res://tests/window_layout_tests.gd','--','--tests')
 Invoke-GodotCheck -GodotArgs @('--headless','--script','res://tests/reference_scene_tests.gd','--','--tests')
 Invoke-GodotCheck -GodotArgs @('--headless','--script','res://tests/floating_interaction_tests.gd','--','--tests')
 Invoke-GodotCheck -GodotArgs @('--headless','--script','res://tests/window_controls_tests.gd','--','--tests')
 Invoke-GodotCheck -GodotArgs @('--audio-driver','Dummy','--rendering-method','gl_compatibility','--script','res://tests/floating_interaction_tests.gd','--','--tests')
 Invoke-GodotCheck -GodotArgs @('--audio-driver','Dummy','--rendering-method','gl_compatibility','--script','res://tests/floating_interaction_capture.gd','--','--tests')
 Invoke-GodotCheck -GodotArgs @('--audio-driver','Dummy','--rendering-method','gl_compatibility','--script','res://tests/window_controls_tests.gd','--','--tests')
 Invoke-GodotCheck -GodotArgs @('--audio-driver','Dummy','--rendering-method','gl_compatibility','--script','res://tests/window_layout_capture.gd','--','--tests')
 Invoke-GodotCheck -GodotArgs @('--headless','--script','res://tests/run_windows_focus.gd','--','--tests')
 Invoke-GodotCheck -GodotArgs @('--headless','--quit-after','180','--','--tests','--ui-smoke')
 Invoke-GodotCheck -GodotArgs @('--headless','--quit-after','180','--','--tests','--ui-smoke','--small')
 foreach ($mode in @('--catch','--book','--tank','--samples')) {
  Invoke-GodotCheck -GodotArgs @('--audio-driver','Dummy','--rendering-method','gl_compatibility','--quit-after','180','--','--tests','--collection-capture',$mode)
 }
 foreach ($scenario in @('catch','replace','error','empty','book','confirm')) {
  $reviewArgs = @('--audio-driver','Dummy','--rendering-method','gl_compatibility','--quit-after','180','--','--tests','--collection-capture','--ui-review','--small')
  switch ($scenario) {
   'catch' { $reviewArgs += '--catch' }
   'replace' { $reviewArgs += @('--tank','--replace') }
   'error' { $reviewArgs += @('--tank','--replace','--error') }
   'empty' { $reviewArgs += @('--tank','--empty') }
   'book' { $reviewArgs += @('--book','--undiscovered') }
   'confirm' { $reviewArgs += @('--tank','--replace','--confirm') }
  }
  Invoke-GodotCheck -GodotArgs $reviewArgs
 }
 foreach ($profile in @('scene','mini')) {
  foreach ($backdrop in @('light','dark','transparent')) {
   Invoke-GodotCheck -GodotArgs @('--audio-driver','Dummy','--rendering-method','gl_compatibility','--quit-after','180','--script','res://tests/floating_art_capture.gd','--','--tests',"--profile=$profile","--backdrop=$backdrop")
  }
 }
 foreach ($mode in @('--day','--night','--cast-pose','--reel-pose')) {
  Invoke-GodotCheck -GodotArgs @('--audio-driver','Dummy','--rendering-method','gl_compatibility','--quit-after','180','--','--tests','--scene-capture','--stage4',$mode)
 }
 Invoke-GodotCheck -GodotArgs @('--audio-driver','Dummy','--rendering-method','gl_compatibility','--quit-after','180','--','--tests','--scene-capture','--stage4','--small')
}
