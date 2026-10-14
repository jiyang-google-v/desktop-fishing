param([int]$X,[int]$Y)
$ErrorActionPreference = 'Stop'
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class ToolbarTestMouse {
 [DllImport("user32.dll")] public static extern bool SetCursorPos(int x,int y);
 [DllImport("user32.dll")] public static extern void mouse_event(uint flags,uint x,uint y,uint data,UIntPtr info);
}
'@
if (-not [ToolbarTestMouse]::SetCursorPos($X,$Y)) { exit 2 }
[ToolbarTestMouse]::mouse_event(2,0,0,0,[UIntPtr]::Zero)
[ToolbarTestMouse]::mouse_event(4,0,0,0,[UIntPtr]::Zero)
