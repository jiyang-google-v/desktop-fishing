$ErrorActionPreference = 'Stop'
$worker = Join-Path $PSScriptRoot '../platform/windows/focus-worker.ps1'
$output = Join-Path $env:TEMP ('fishing-focus-test-' + [guid]::NewGuid().ToString('N') + '.json')
$token = [guid]::NewGuid().ToString('N')
$arguments = @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',('"' + (Resolve-Path $worker).Path + '"'),'-ParentProcessId',"$PID",'-OutputPath',('"' + $output + '"'),'-Token',$token)
$process = Start-Process powershell.exe -ArgumentList $arguments -PassThru -WindowStyle Hidden
try {
 $deadline = [DateTime]::UtcNow.AddSeconds(20)
 while (!(Test-Path -LiteralPath $output) -and [DateTime]::UtcNow -lt $deadline) { Start-Sleep -Milliseconds 250 }
 if (!(Test-Path -LiteralPath $output)) { throw 'Focus helper produced no sample' }
 $value = Get-Content -LiteralPath $output -Raw | ConvertFrom-Json
 if ($value.token -ne $token -or !$value.supported -or $value.idle_seconds -lt 0) { throw 'Invalid focus sample' }
 if ($value.foreground -isnot [bool] -or $value.locked -isnot [bool]) { throw 'Missing boolean state' }
 if ([Math]::Abs([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()/1000.0 - $value.sampled_at) -gt 5) { throw 'Stale sample' }
 if ($value.epoch -lt 1 -or $value.sequence -lt 1) { throw 'Invalid continuity marker' }
 $deadline = [DateTime]::UtcNow.AddSeconds(5)
 do {
  Start-Sleep -Milliseconds 250
  $next = Get-Content -LiteralPath $output -Raw | ConvertFrom-Json
 } while ($next.sequence -le $value.sequence -and [DateTime]::UtcNow -lt $deadline)
 if ($next.sequence -le $value.sequence) { throw 'Worker stopped sampling' }
 Write-Host 'Windows native focus helper smoke passed'
} finally {
 if (!$process.HasExited) { Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue }
 Remove-Item -LiteralPath $output,($output + '.tmp') -Force -ErrorAction SilentlyContinue
}
