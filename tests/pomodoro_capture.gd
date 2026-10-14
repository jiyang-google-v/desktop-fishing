extends SceneTree
func _initialize() -> void:
 call_deferred('run')
func save_view(viewport: Viewport, filename: String) -> void:
 for i in 3:
  await process_frame
 RenderingServer.force_draw()
 assert(viewport.get_texture().get_image().save_png('res://docs/qa/pomodoro/'+filename+'.png') == OK)
func run() -> void:
 var main = load('res://scenes/main.tscn').instantiate()
 root.add_child(main)
 var game = root.get_node('Game')
 DirAccess.make_dir_recursive_absolute('res://docs/qa/pomodoro')
 await process_frame
 for entry in [['ready',25,0.0,false],['working',45,600.0,false],['paused',45,600.0,true],['completed',60,3600.0,false]]:
  game.state = game.model.fresh_state()
  game.state.duration_minutes = entry[1]
  if entry[0] != 'ready':
   game.model.cast_line(game.state)
   game.state.focus_seconds = entry[2]
   game.state.paused = entry[3]
   game.state.pause_cause = 'manual' if entry[3] else ''
  main.refresh()
  await save_view(root,entry[0])
 game.model.reel_line(game.state,12,game.rng)
 main.refresh()
 await save_view(root,'catch')
 main.open_collection('book')
 main.book_group = 'C'
 main.panel_signature = ''
 main.render_collection()
 await save_view(main.collection,'book-C')
 main.close_collection()
 game.state = game.model.fresh_state()
 game.model.cast_line(game.state)
 game.state.focus_seconds = 600.0
 game.state.paused = true
 game.state.pause_cause = 'manual'
 main.refresh()
 main.layouts.apply('mini',false)
 main.layouts.set_process(false)
 main.layouts.show_tools()
 await save_view(main.layouts.tools,'mini-timer-toolbar')
 main.layouts.tools.hide()
 print('Captured Pomodoro ready/running/paused/completed/catch/grouped-book/floating toolbar')
 quit()
