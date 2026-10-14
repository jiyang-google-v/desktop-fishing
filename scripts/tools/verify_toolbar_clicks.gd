# Test-only physical Windows mouse clicks on the exported native toolbar.
extends RefCounted
static func run(main: Control) -> void:
 var tree := main.get_tree()
 if OS.get_name() != 'Windows':
  tree.quit(0)
  return
 var layouts = main.layouts
 main.get_window().always_on_top = true
 layouts.pinned = true
 layouts.apply('scene',false)
 layouts.show_tools()
 layouts.hover_grace = 8.0
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
 for target in ['mini','scene','mini','scene']:
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
 var game = main.get_node('/root/Game')
 var save_path: String = 'user://toolbar-test-'+game.model.new_id()+'.json'
 game.save_path = save_path
 for origin in ['scene','mini']:
  layouts.apply(origin,false)
  for kind in ['book','tank','reel']:
   game.state = game.model.fresh_state()
   game.model.cast_line(game.state)
   main.ocean.skip()
   main.refresh()
   layouts.show_tools()
   layouts.hover_grace = 8.0
   for i in 4:
    await tree.process_frame
   var button: Button = layouts.action_buttons[kind]
   var center: Vector2i = layouts.tools.position+Vector2i(button.get_global_rect().get_center())
   var output := []
   var result := OS.execute('powershell.exe',PackedStringArray(['-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',ProjectSettings.globalize_path(helper),'-X',str(center.x),'-Y',str(center.y)]),output)
   await tree.create_timer(.35).timeout
   var worked: bool = main.confirmation.visible if kind == 'reel' else (main.collection.visible and main.panel_mode == kind)
   if result != 0 or not worked:
    push_error('Physical action click failed: origin=%s action=%s output=%s' % [origin,kind,output])
    tree.quit(1)
    return
   if kind == 'reel':
    main.confirmation.hide()
    main.confirmation.canceled.emit()
   else:
    main.close_collection()
   print('Physical Windows toolbar action passed: '+origin+' / '+kind)
  layouts.show_tools()
  layouts.hover_grace = 8.0
  for i in 4:
   await tree.process_frame
  var center: Vector2i = layouts.tools.position+Vector2i(layouts.mode_buttons.full.get_global_rect().get_center())
  var output := []
  OS.execute('powershell.exe',PackedStringArray(['-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',ProjectSettings.globalize_path(helper),'-X',str(center.x),'-Y',str(center.y)]),output)
  await tree.create_timer(.35).timeout
  if layouts.mode != 'full':
   push_error('Return to full failed from '+origin)
   tree.quit(1)
   return
 for suffix in ['', '.bak','.tmp']:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path+suffix))
 DirAccess.remove_absolute(ProjectSettings.globalize_path(helper))
 print('Exported native toolbar physical clicks passed: scene <-> mini and return to full.')
 tree.quit(0)
