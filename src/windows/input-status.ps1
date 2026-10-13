Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class DesktopFishingInput {
  [StructLayout(LayoutKind.Sequential)] public struct LASTINPUTINFO { public uint cbSize; public uint dwTime; }
  [DllImport("user32.dll")] public static extern bool GetLastInputInfo(ref LASTINPUTINFO info);
  [DllImport("kernel32.dll")] public static extern uint GetTickCount();
}
'@
$info = New-Object DesktopFishingInput+LASTINPUTINFO
$info.cbSize = [System.Runtime.InteropServices.Marshal]::SizeOf($info)
if (-not [DesktopFishingInput]::GetLastInputInfo([ref]$info)) { exit 1 }
$idleMs = [uint32]([DesktopFishingInput]::GetTickCount() - $info.dwTime)
@{ idleSeconds = [Math]::Round($idleMs / 1000.0, 2) } | ConvertTo-Json -Compress
