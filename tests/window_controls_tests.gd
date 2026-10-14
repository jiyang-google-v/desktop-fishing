extends SceneTree
func _initialize() -> void:
 call_deferred('run')
func run() -> void:
 var main = load('res://scenes/main.tscn').instantiate()
 root.add_child(main)
 await process_frame
 var layouts = main.layouts
 var game = main.get_node('/root/Game')
 var initial: String = JSON.stringify(game.state)
 for origin in ['full','scene','mini']:
  for target in ['full','scene','mini']:
   layouts.apply(origin,false)
   await process_frame
   layouts.apply(target,false)
   await process_frame
   assert(layouts.mode == target)
   if DisplayServer.get_name() != 'headless':
    assert(root.size == (Vector2i(1100,760) if target == 'full' else layouts.SIZES[target]))
   assert(JSON.stringify(game.state) == initial)
 for origin in ['scene','mini']:
  for target in ['full','scene','mini']:
   layouts.apply(origin,false)
   layouts.mode_buttons[target].pressed.emit()
   await process_frame
   assert(layouts.mode == target)
 for mode in ['scene','mini']:
  layouts.apply(mode,false)
  var rig: Dictionary = layouts.view.rig_geometry()
  assert(layouts.should_show_tools(root.position+Vector2i(rig.tip)))
  layouts.show_tools()
  assert(layouts.tools.visible)
  assert(layouts.mode_buttons.size() == 3)
  assert(layouts.action_buttons.size() == 3)
  assert(layouts.action_buttons.reel.disabled)
  assert(layouts.view.material != null)
  assert(layouts.view.brightness_lift > 0)
  layouts.open_collection('book')
  assert(layouts.mode == mode and main.collection.visible and main.panel_mode == 'book')
  main.close_collection()
  layouts.open_collection('tank')
  assert(layouts.mode == mode and main.collection.visible and main.panel_mode == 'tank')
  main.close_collection()
  layouts.tools.hide()
 print('All nine layout transitions, rod-hover toolbar, collection entry points and brightness lift passed')
 quit()
