param([int]$X,[int]$Y,[int]$Wheel=0)
$ErrorActionPreference = 'Stop'
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class ToolbarTestMouse {
 public static void Scroll(int delta) { mouse_event(0x0800,0,0,unchecked((uint)delta),UIntPtr.Zero); }
 [DllImport("user32.dll")] public static extern bool SetCursorPos(int x,int y);
 [DllImport("user32.dll")] public static extern void mouse_event(uint flags,uint x,uint y,uint data,UIntPtr info);
}
'@
if (-not [ToolbarTestMouse]::SetCursorPos($X,$Y)) { exit 2 }
if ($Wheel -ne 0) { [ToolbarTestMouse]::Scroll($Wheel); exit 0 }
[ToolbarTestMouse]::mouse_event(2,0,0,0,[UIntPtr]::Zero)
[ToolbarTestMouse]::mouse_event(4,0,0,0,[UIntPtr]::Zero)
