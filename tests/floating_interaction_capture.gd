extends SceneTree
func _initialize() -> void:
 call_deferred('run')
func capture(window: Window, path: String) -> void:
 for i in 6:
  await process_frame
 RenderingServer.force_draw()
 assert(window.get_texture().get_image().save_png(path) == OK)
func run() -> void:
 var main = load('res://scenes/main.tscn').instantiate()
 root.add_child(main)
 await process_frame
 var game = root.get_node('Game')
 var layouts = main.layouts
 layouts.set_process(false)
 DirAccess.make_dir_recursive_absolute('res://docs/qa/floating-controls')
 for mode in ['scene','mini']:
  game.state = game.model.fresh_state()
  layouts.apply(mode,false)
  layouts.show_tools()
  layouts.tool_action('opacity')
  await capture(layouts.tools,'res://docs/qa/floating-controls/'+mode+'-tools.png')
  assert(Rect2(Vector2.ZERO,Vector2(layouts.tools.size)).encloses(layouts.opacity_label.get_global_rect()))
  layouts.set_opacity_percent(60)
  await capture(root,'res://docs/qa/floating-controls/'+mode+'-opacity.png')
  layouts.set_opacity_percent(100)
  game.model.cast_line(game.state)
  game.state.focus_seconds = game.state.duration_minutes*60.0
  game.model.reel_line(game.state,12,RandomNumberGenerator.new())
  layouts.view.action = 'reel'
  layouts.view.action_progress = .6
  layouts.view.caught_texture = main.Portrait.texture_for(game.state.pending_catch.species_id)
  await capture(root,'res://docs/qa/floating-controls/'+mode+'-reel.png')
  main.ocean.skip()
  layouts.sync_catch()
  await create_timer(.45).timeout
  await capture(layouts.catch_popup,'res://docs/qa/floating-controls/'+mode+'-catch.png')
  assert(Rect2(Vector2.ZERO,Vector2(layouts.catch_popup.size)).encloses(layouts.catch_popup.later_button.get_global_rect()))
 print('Captured actual-size opacity, toolbar, reeling and catch cards in both floating layouts')
 quit()
