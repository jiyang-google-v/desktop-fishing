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
 for target in ['mini','scene','mini','scene','mini','scene','mini','scene','mini','scene','mini','scene']:
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
  game.state = game.model.fresh_state()
  game.model.cast_line(game.state)
  game.state.focus_seconds = 24.0
  game.focus_status = {'supported':true,'locked':false}
  main.refresh()
  layouts.tools.hide()
  var root_position: Vector2i = main.get_window().position
  for expected_pause in [true,false]:
   layouts.sync_tools()
   for i in 4:
    await tree.process_frame
   var center: Vector2i = main.get_window().position+Vector2i(layouts.timer_card.pause_button.get_global_rect().get_center())
   var output := []
   var result := OS.execute('powershell.exe',PackedStringArray(['-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',ProjectSettings.globalize_path(helper),'-X',str(center.x),'-Y',str(center.y)]),output)
   await tree.create_timer(.35).timeout
   if result != 0 or game.state.paused != expected_pause or game.state.focus_seconds != 24.0 or main.get_window().position != root_position:
    push_error('Physical Card A pause/resume click failed: '+origin)
    tree.quit(1)
    return
  print('Physical Windows Card A pause/resume passed: '+origin)
  game.state = game.model.fresh_state()
  main.ocean.skip()
  main.refresh()
  layouts.show_tools()
  layouts.hover_grace = 8.0
  for i in 4:
   await tree.process_frame
  var cast_result: bool = await click_control(main,layouts.action_buttons.cast,layouts.tools,helper)
  if not cast_result or not game.state.cast or layouts.mode != origin:
   push_error('Physical floating cast failed: '+origin)
   tree.quit(1)
   return
  main.ocean.skip()
  layouts.show_tools()
  layouts.hover_grace = 8.0
  for i in 4:
   await tree.process_frame
  if not await click_control(main,layouts.action_buttons.opacity,layouts.tools,helper) or not layouts.opacity_open:
   push_error('Physical opacity button failed: '+origin)
   tree.quit(1)
   return
  for i in 4:
   await tree.process_frame
  if not await click_control(main,layouts.opacity_slider,layouts.tools,helper) or layouts.opacity_percent() == 100:
   push_error('Physical opacity slider failed: '+origin)
   tree.quit(1)
   return
  layouts.set_opacity_percent(100)
  game.state.focus_seconds = game.state.duration_minutes*60.0
  main.refresh()
  layouts.show_tools()
  layouts.hover_grace = 8.0
  for i in 4:
   await tree.process_frame
  if not await click_control(main,layouts.action_buttons.reel,layouts.tools,helper) or game.state.pending_catch.is_empty():
   push_error('Physical completed reel failed: '+origin)
   tree.quit(1)
   return
  await tree.create_timer(2.0).timeout
  if not layouts.catch_popup.visible:
   push_error('Floating catch reveal failed: '+origin)
   tree.quit(1)
   return
  if not await click_control(main,layouts.catch_popup.keep_button,layouts.catch_popup,helper) or not game.state.pending_catch.is_empty():
   push_error('Physical catch keep failed: '+origin)
   tree.quit(1)
   return
  print('Physical cast / opacity slider / reel / catch keep passed: '+origin)
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

static func click_control(main: Control, control: Control, window: Window, helper: String) -> bool:
 var center: Vector2i = window.position+Vector2i(control.get_global_rect().get_center())
 var output := []
 var result := OS.execute('powershell.exe',PackedStringArray(['-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',ProjectSettings.globalize_path(helper),'-X',str(center.x),'-Y',str(center.y)]),output)
 await main.get_tree().create_timer(.35).timeout
 return result == 0
