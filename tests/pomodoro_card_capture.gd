extends SceneTree
func _initialize() -> void:
 call_deferred('run')
func run() -> void:
 var main = load('res://scenes/main.tscn').instantiate()
 root.add_child(main)
 await process_frame
 var game = root.get_node('Game')
 game.state = game.model.fresh_state()
 game.model.cast_line(game.state)
 game.state.focus_seconds = 24.0
 main.refresh()
 main.layouts.set_process(false)
 DirAccess.make_dir_recursive_absolute('res://docs/qa/pomodoro-card')
 for mode in ['scene','mini']:
  main.layouts.apply(mode,false)
  main.layouts.tools.hide()
  for state in ['day','night','paused','completed']:
   game.state.focus_seconds = 1500.0 if state == 'completed' else 24.0
   game.state.paused = state == 'paused'
   main.ocean.night = state == 'night'
   main.layouts.view.night = main.ocean.night
   main.layouts.view.queue_redraw()
   main.layouts.sync_tools()
   for i in 4:
    await process_frame
   RenderingServer.force_draw()
   assert(root.get_texture().get_image().save_png('res://docs/qa/pomodoro-card/'+mode+'-'+state+'.png') == OK)
 main.layouts.apply('full',false)
 print('Captured Card A: actual-size scene/mini, day/night/pause/complete')
 quit()
