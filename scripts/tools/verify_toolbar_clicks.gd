# Test-only physical Windows mouse clicks on the exported native toolbar.
extends RefCounted
static func run(main: Control) -> void:
 var tree := main.get_tree()
 if OS.get_name() != 'Windows':
  tree.quit(0)
  return
 var layouts = main.layouts
 layouts.set_process(false)
 main.get_window().always_on_top = true
 layouts.pinned = true
 layouts.apply('scene',false)
 layouts.show_tools()
 for i in 4:
  await tree.process_frame
 var anchor: Vector2i = layouts.tools.position
 var state: String = JSON.stringify(main.get_node('/root/Game').state)
 var helper := 'user://toolbar-click-test.ps1'
 var file := FileAccess.open(helper,FileAccess.WRITE)
 if file == null:
  tree.quit(1)
  return
 file.store_string(FileAccess.get_file_as_string('res://platform/windows/toolbar-click-test.ps1'))
 file.close()
 for target in ['mini','scene','mini','scene','full']:
  var button: Button = layouts.mode_buttons[target]
  var center: Vector2i = layouts.tools.position+Vector2i(button.get_global_rect().get_center())
  var output := []
  var result := OS.execute('powershell.exe',PackedStringArray(['-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',ProjectSettings.globalize_path(helper),'-X',str(center.x),'-Y',str(center.y)]),output)
  await tree.create_timer(.35).timeout
  if result != 0 or layouts.mode != target or JSON.stringify(main.get_node('/root/Game').state) != state:
   push_error('Physical toolbar click failed: target=%s actual=%s helper=%d output=%s' % [target,layouts.mode,result,output])
   tree.quit(1)
   return
  if target != 'full' and (not layouts.tools.visible or layouts.tools.position != anchor):
   push_error('Toolbar disappeared or moved during scene/mini button switch.')
   tree.quit(1)
   return
  print('Physical Windows toolbar click passed: '+target)
 DirAccess.remove_absolute(ProjectSettings.globalize_path(helper))
 print('Exported native toolbar physical clicks passed: scene <-> mini and return to full.')
 tree.quit(0)
