extends SceneTree
func _initialize() -> void:
 call_deferred('run')
func run() -> void:
 var main = load('res://scenes/main.tscn').instantiate()
 root.add_child(main)
 await process_frame
 var layouts = main.layouts
 assert(ProjectSettings.get_setting('display/window/size/transparent'))
 assert(ProjectSettings.get_setting('rendering/viewport/transparent_background'))
 assert(ProjectSettings.get_setting('rendering/gl_compatibility/driver.windows') == 'opengl3_angle')
 var snapshot: String = JSON.stringify(main.get_node('/root/Game').state)
 for mode in ['scene','mini','full','mini','scene','full']:
  layouts.apply(mode, false)
  await process_frame
  assert(layouts.mode == mode)
  assert(main.get_node('LayoutMargin').visible == (mode == 'full'))
  assert(layouts.view.visible == (mode != 'full'))
  if DisplayServer.get_name() != 'headless':
   assert(root.borderless)
  assert(root.transparent_bg)
  assert(layouts.background.visible == (mode == 'full'))
  assert(JSON.stringify(main.get_node('/root/Game').state) == snapshot)
  if mode != 'full':
   assert(layouts.view.profile == mode)
   assert(root.min_size == layouts.SIZES[mode])
 for mode in ['scene','mini']:
  layouts.apply(mode,false)
  for action in ['cast','reel']:
   main.ocean.play(action)
   assert(main.ocean.is_busy())
   main.ocean._process(10.0)
   assert(not main.ocean.is_busy())
 layouts.apply('full',false)
 layouts.apply('invalid', false)
 assert(layouts.mode == 'full')
 assert(layouts.clamp_position(Vector2i(-99999,99999),Vector2i(160,100)).y < 99999)
 print('Three window layouts: visibility, transparency, size, state preservation and bounds passed')
 quit()
