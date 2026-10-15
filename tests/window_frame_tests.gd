extends SceneTree
func _initialize() -> void:
 call_deferred('run')
func run() -> void:
 var main = load('res://scenes/main.tscn').instantiate()
 root.add_child(main)
 await process_frame
 var layouts = main.layouts
 var frame = layouts.frame
 var game = root.get_node('Game')
 layouts.settings.set_value('window','frame_version',0)
 layouts.settings.set_value('full','size',Vector2i(1100,760))
 layouts.migrate_frame_settings()
 assert(layouts.settings.get_value('full','size') == Vector2i(1100,796))
 layouts.migrate_frame_settings()
 assert(layouts.settings.get_value('full','size') == Vector2i(1100,796))
 var state: String = JSON.stringify(game.state)
 for mode in ['full','scene','mini','full']:
  layouts.apply(mode,false)
  await process_frame
  assert(frame.visible == (mode == 'full'))
  assert(root.borderless or DisplayServer.get_name() == 'headless')
  assert(main.get_node('LayoutMargin').get_theme_constant('margin_top') == 60)
  assert(JSON.stringify(game.state) == state)
 assert(frame.bar.size.y == 36)
 assert(frame.buttons.size() == 3 and frame.handles.size() == 8)
 assert(frame.buttons.close.tooltip_text.contains('保存'))
 if OS.get_name() == 'Windows' and DisplayServer.get_name() != 'headless':
  frame.toggle_maximize()
  await process_frame
  assert(frame.is_maximized(), "Maximize state mismatch: mode=%s, size=%s, work_area=%s" % [root.mode,root.size,DisplayServer.screen_get_usable_rect(root.current_screen)])
  assert(bool(layouts.settings.get_value('full','maximized',false)))
  var screen := root.current_screen
  var work_area := DisplayServer.screen_get_usable_rect(screen)
  print('Native maximize mode=%s, size=%s, work_area=%s' % [root.mode,root.size,work_area])
  # Godot removes its two-pixel off-screen compensation from client size.
  assert(root.size.x == work_area.size.x and root.size.y in [work_area.size.y,work_area.size.y-2])
  layouts.apply('mini')
  await process_frame
  assert(root.mode == Window.MODE_WINDOWED and root.size == layouts.SIZES.mini)
  layouts.apply('full')
  await process_frame
  assert(frame.is_maximized(), "Maximize state mismatch: mode=%s, size=%s, work_area=%s" % [root.mode,root.size,DisplayServer.screen_get_usable_rect(root.current_screen)])
  frame.toggle_maximize()
  await process_frame
  assert(root.mode == Window.MODE_WINDOWED)
 var old_path: String = game.save_path
 var old_state: Dictionary = game.state.duplicate(true)
 game.save_path = 'user://missing-titlebar-test/save.json'
 frame.request_close()
 assert(game.state == old_state and game.warning.contains('取消退出'))
 game.save_path = old_path
 print('Custom titlebar: compact visibility, content margin, controls, resize edges and failed-save close cancellation passed')
 quit()
