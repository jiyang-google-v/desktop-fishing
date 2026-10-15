extends SceneTree
func _initialize() -> void:
 call_deferred('run')
func run() -> void:
 var main = load('res://scenes/main.tscn').instantiate()
 root.add_child(main)
 await process_frame
 var game = root.get_node('Game')
 var layouts = main.layouts
 game.state = game.model.fresh_state()
 layouts.apply('scene',false)
 layouts.set_process(false)
 layouts.tools.hide()
 var view = layouts.view
 view.line_cast = true
 view.action = 'idle'
 var path := 'res://docs/qa/mode2-v5/'
 DirAccess.make_dir_recursive_absolute(path)
 for i in 5:
  await process_frame
 RenderingServer.force_draw()
 root.get_texture().get_image().save_png(path+'idle.png')
 view.action = 'reel'
 view.action_progress = .45
 view.line_cast = false
 view.caught_texture = main.Portrait.texture_for('fish_001_clownfish')
 for i in 3:
  await process_frame
 RenderingServer.force_draw()
 root.get_texture().get_image().save_png(path+'reel.png')
 game.model.cast_line(game.state)
 game.state.focus_seconds = game.state.duration_minutes*60.0
 game.model.reel_line(game.state,12,RandomNumberGenerator.new())
 main.ocean.skip()
 layouts.sync_catch()
 layouts.catch_popup.reveal_age = 2.0
 for i in 3:
  await process_frame
 RenderingServer.force_draw()
 layouts.catch_popup.get_texture().get_image().save_png(path+'card.png')
 assert(Rect2(Vector2.ZERO,Vector2(layouts.catch_popup.size)).encloses(layouts.catch_popup.later_button.get_global_rect()))
 print('Mode2 native-size scene, reel and stationary card captured')
 quit()
