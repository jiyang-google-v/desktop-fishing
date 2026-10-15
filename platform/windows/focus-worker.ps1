param(
 [Parameter(Mandatory=$true)][int]$ParentProcessId,
 [Parameter(Mandatory=$true)][string]$OutputPath,
 [Parameter(Mandatory=$true)][string]$Token
)
$ErrorActionPreference = 'Stop'
Add-Type -TypeDefinition @'
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;
public static class FishingFocus {
 [DllImport("kernel32.dll")] public static extern ulong GetTickCount64();
 [DllImport("user32.dll", SetLastError=true)] static extern IntPtr OpenInputDesktop(uint flags, bool inherit, uint access);
 [DllImport("user32.dll")] static extern bool CloseDesktop(IntPtr desktop);
 [DllImport("user32.dll", CharSet=CharSet.Unicode, SetLastError=true)] static extern bool GetUserObjectInformation(IntPtr desktop, int index, StringBuilder value, uint size, out uint needed);
 [DllImport("wtsapi32.dll", CharSet=CharSet.Unicode)] static extern bool WTSQuerySessionInformation(IntPtr server, int session, int info, out IntPtr buffer, out uint bytes);
 [DllImport("wtsapi32.dll")] static extern void WTSFreeMemory(IntPtr buffer);
 public static void Publish(string source, string destination) {
  // Pass a real C# null: Windows PowerShell can coerce $null to an empty string.
  if (System.IO.File.Exists(destination)) System.IO.File.Replace(source, destination, null);
  else System.IO.File.Move(source, destination);
 }
 public static bool Locked() {
  // A disconnected session or an inaccessible/secure input desktop pauses progress.
  IntPtr buffer; uint bytes;
  int session = Process.GetCurrentProcess().SessionId;
  if (!WTSQuerySessionInformation(IntPtr.Zero, session, 8, out buffer, out bytes)) return true;
  try { if (bytes < 4 || Marshal.ReadInt32(buffer) != 0) return true; }
  finally { WTSFreeMemory(buffer); }
  IntPtr desktop = OpenInputDesktop(0, false, 1);
  if (desktop == IntPtr.Zero) return true;
  try {
   StringBuilder name = new StringBuilder(256); uint needed;
   if (!GetUserObjectInformation(desktop, 2, name, 512, out needed)) return true;
   return !String.Equals(name.ToString(), "Default", StringComparison.OrdinalIgnoreCase);
  } finally { CloseDesktop(desktop); }
 }
}
'@
$sequence = 0
$epoch = 0
$previousTick = [FishingFocus]::GetTickCount64()
$previousState = ""
$encoding = New-Object System.Text.UTF8Encoding($false)
try {
 while ($null -ne (Get-Process -Id $ParentProcessId -ErrorAction SilentlyContinue)) {
  $sequence++
  $idle = 0.0 # Compatibility schema only; no input activity is queried.
  $foreground = $false # Foreground is irrelevant to self-defined focus.
  $locked = [FishingFocus]::Locked()
  $tick = [FishingFocus]::GetTickCount64()
  # Preserve observed interruptions even when Godot misses an intermediate sample.
  $signature = "$locked"
  if ($signature -ne $previousState -or ($tick - $previousTick) -gt 2000) { $epoch++ }
  $previousState = $signature
  $previousTick = $tick
  $state = @{
   token = $Token
   sequence = $sequence
   epoch = $epoch
   sampled_at = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() / 1000.0
   supported = $idle -ge 0
   idle_seconds = $idle
   foreground = $foreground
   locked = $locked
  }
  $json = $state | ConvertTo-Json -Compress
  try {
   [IO.File]::WriteAllText($OutputPath + '.tmp', $json, $encoding)
   [FishingFocus]::Publish($OutputPath + '.tmp', $OutputPath)
  } catch { }
  Start-Sleep -Milliseconds 500
 }
} finally {
 Remove-Item -LiteralPath $OutputPath -Force -ErrorAction SilentlyContinue
 Remove-Item -LiteralPath ($OutputPath + '.tmp') -Force -ErrorAction SilentlyContinue
}
