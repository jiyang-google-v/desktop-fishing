param([int]$X,[int]$Y,[int]$DragX=-1,[int]$DragY=-1,[switch]$DoubleClick)
$ErrorActionPreference = 'Stop'
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class WindowFrameMouse {
 [DllImport("user32.dll")] public static extern bool SetCursorPos(int x,int y);
 [DllImport("user32.dll")] public static extern void mouse_event(uint flags,uint x,uint y,uint data,UIntPtr info);
}
'@
if (-not [WindowFrameMouse]::SetCursorPos($X,$Y)) { exit 2 }
Start-Sleep -Milliseconds 80
[WindowFrameMouse]::mouse_event(2,0,0,0,[UIntPtr]::Zero)
Start-Sleep -Milliseconds 120
if ($DragX -ge 0 -and $DragY -ge 0) {
 for ($step = 1; $step -le 12; $step++) {
  [void][WindowFrameMouse]::SetCursorPos([int]($X+($DragX-$X)*$step/12),[int]($Y+($DragY-$Y)*$step/12))
  Start-Sleep -Milliseconds 30
 }
}
[WindowFrameMouse]::mouse_event(4,0,0,0,[UIntPtr]::Zero)
if ($DoubleClick) {
 Start-Sleep -Milliseconds 70
 [WindowFrameMouse]::mouse_event(2,0,0,0,[UIntPtr]::Zero)
 Start-Sleep -Milliseconds 80
 [WindowFrameMouse]::mouse_event(4,0,0,0,[UIntPtr]::Zero)
}
