extends RefCounted
static func mouse(main: Control, point: Vector2i, target: Vector2i = Vector2i(-1,-1), double_click: bool = false) -> bool:
 var args := PackedStringArray(['-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',ProjectSettings.globalize_path('user://window-frame-test.ps1'),'-X',str(point.x),'-Y',str(point.y)])
 if target.x >= 0:
  args.append_array(PackedStringArray(['-DragX',str(target.x),'-DragY',str(target.y)]))
 if double_click:
  args.append('-DoubleClick')
 var pid: int = OS.create_process('powershell.exe',args)
 if pid < 0:
  return false
 var deadline: int = Time.get_ticks_msec()+12000
 while OS.is_process_running(pid) and Time.get_ticks_msec() < deadline:
  await main.get_tree().create_timer(.05).timeout
 await main.get_tree().create_timer(.2).timeout
 return not OS.is_process_running(pid)
static func center(main: Control, button: Control) -> Vector2i:
 return main.get_window().position+Vector2i(button.get_global_rect().get_center())
static func run(main: Control) -> void:
 var tree := main.get_tree()
 if OS.get_name() != 'Windows':
  tree.quit()
  return
 var game = main.get_node('/root/Game')
 game.state = game.model.fresh_state()
 game.save_path = 'user://window-frame-native.json'
 var helper := FileAccess.open('user://window-frame-test.ps1',FileAccess.WRITE)
 helper.store_string(FileAccess.get_file_as_string('res://platform/windows/window-frame-test.ps1'))
 helper.close()
 var layouts = main.layouts
 var frame = layouts.frame
 var window := main.get_window()
 layouts.pinned = true
 layouts.apply('full',false)
 window.position = DisplayServer.screen_get_usable_rect().position+Vector2i(40,40)
 for i in 6:
  await tree.process_frame
 var old_position := window.position
 var from := old_position+Vector2i(300,18)
 if not await mouse(main,from,from+Vector2i(45,30)) or window.position.distance_to(old_position+Vector2i(45,30)) > 5:
  push_error('Native titlebar drag failed')
  tree.quit(1)
  return
 print('Native titlebar drag passed')
 var old_size := window.size
 from = window.position+old_size-Vector2i(3,3)
 if not await mouse(main,from,from+Vector2i(40,30)) or window.size.distance_to(old_size+Vector2i(40,30)) > 8:
  push_error('Native border resize failed')
  tree.quit(1)
  return
 if window.content_scale_size != window.size:
  push_error('Resize changed UI scale instead of content space')
  tree.quit(1)
  return
 print('Native border resize passed')
 if not await mouse(main,center(main,frame.buttons.maximize)) or window.mode != Window.MODE_MAXIMIZED:
  push_error('Native maximize button failed')
  tree.quit(1)
  return
 layouts.apply('mini')
 await tree.create_timer(.25).timeout
 if window.mode != Window.MODE_WINDOWED or window.size != layouts.SIZES.mini:
  push_error('Maximized full to mini failed')
  tree.quit(1)
  return
 layouts.apply('full')
 await tree.create_timer(.25).timeout
 if window.mode != Window.MODE_MAXIMIZED:
  push_error('Returning to maximized full failed')
  tree.quit(1)
  return
 if not await mouse(main,center(main,frame.buttons.maximize)) or window.mode != Window.MODE_WINDOWED:
  push_error('Native restore button failed')
  tree.quit(1)
  return
 print('Native maximize/restore and compact round-trip passed')
 if not await mouse(main,window.position+Vector2i(300,18),Vector2i(-1,-1),true) or window.mode != Window.MODE_MAXIMIZED:
  push_error('Native titlebar double-click failed')
  tree.quit(1)
  return
 if not await mouse(main,center(main,frame.buttons.maximize)) or window.mode != Window.MODE_WINDOWED:
  push_error('Restore after double-click failed')
  tree.quit(1)
  return
 print('Native double-click maximize passed')
 if not await mouse(main,center(main,frame.buttons.minimize)) or window.mode != Window.MODE_MINIMIZED:
  push_error('Native minimize button failed')
  tree.quit(1)
  return
 window.mode = Window.MODE_WINDOWED
 await tree.create_timer(.3).timeout
 print('Native minimize passed')
 var snapshot: Dictionary = game.state.duplicate(true)
 game.save_path = 'user://window-frame-missing/save.json'
 if not await mouse(main,center(main,frame.buttons.close)) or game.state != snapshot or not game.warning.contains('取消退出'):
  push_error('Failed-save native close was not canceled')
  tree.quit(1)
  return
 print('Native close canceled on save failure passed')
 game.save_path = 'user://window-frame-native.json'
 game.state = game.model.fresh_state()
 game.model.cast_line(game.state)
 game.state.focus_seconds = 123.0
 print('Native titlebar controls passed; requesting save and close')
 await mouse(main,center(main,frame.buttons.close))
 push_error('Successful save and close did not exit')
 tree.quit(1)
