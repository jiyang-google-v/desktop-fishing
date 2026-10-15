extends SceneTree
var folder := 'res://docs/qa/floating-complete/'
func _initialize() -> void:
 call_deferred('run')
func capture(window: Window, file: String) -> void:
 for i in 5:
  await process_frame
 RenderingServer.force_draw()
 window.get_texture().get_image().save_png(folder+file+'.png')
func run() -> void:
 DirAccess.make_dir_recursive_absolute(folder)
 var main = load('res://scenes/main.tscn').instantiate()
 root.add_child(main)
 await process_frame
 var game = root.get_node('Game')
 var layouts = main.layouts
 game.state = game.model.fresh_state()
 for i in 6:
  game.model.cast_line(game.state)
  game.state.focus_seconds = game.state.duration_minutes*60.0
  game.model.reel_line(game.state,12,RandomNumberGenerator.new())
  game.model.settle(game.state,'keep')
 game.state.focus_seconds=0
 main.refresh()
 for mode in ['scene','mini']:
  layouts.apply(mode,false)
  layouts.set_process(false)
  layouts.tools.hide()
  layouts.view.action='idle'
  layouts.view.line_cast=true
  await capture(root,mode+'-idle')
  layouts.view.action='reel'
  layouts.view.action_progress=.42
  layouts.view.line_cast=false
  layouts.view.caught_texture = main.Portrait.texture_for('fish_001_clownfish')
  await capture(root,mode+'-reel')
  layouts.open_settings()
  await capture(layouts.control_panel,mode+'-settings')
  layouts.control_panel.hide()
 main.open_collection('book')
 await capture(main.collection,'book')
 main.close_collection()
 main.open_collection('tank')
 await capture(main.collection,'tank')
 assert(main.collection_grid.get_child_count()==6)
 assert(main.collection_tabs.tank.disabled)
 main.close_collection()
 game.model.cast_line(game.state)
 game.state.focus_seconds = game.state.duration_minutes*60.0
 game.model.reel_line(game.state,12,RandomNumberGenerator.new())
 layouts.sync_catch()
 layouts.catch_popup.reveal_age=2
 await capture(layouts.catch_popup,'mini-card')
 print('Captured scene/mini idle and reel, shared settings, book/tank and stationary catch card')
 quit()
