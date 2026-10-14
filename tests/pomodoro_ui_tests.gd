extends SceneTree
func _initialize() -> void:
 call_deferred('run')
func run() -> void:
 var main = load('res://scenes/main.tscn').instantiate()
 root.add_child(main)
 await process_frame
 var game = root.get_node('Game')
 var path: String = 'user://pomodoro-ui-'+game.model.new_id()+'.json'
 game.save_path = path
 game.state = game.model.fresh_state()
 game.focus_status = {'supported':true,'locked':false,'foreground':true,'idle_seconds':99999}
 assert(game.set_duration(30).ok)
 main.refresh()
 assert(main.pool_preview.text.contains('B 类') and main.time_text.text == '30:00')
 main.perform_fishing('cast')
 main.ocean.skip()
 assert(game.state.cast and not main.duration_input.editable)
 main.perform_fishing('reel')
 assert(main.confirmation.visible and main.confirmation.dialog_text.contains('失败'))
 main.confirmation.hide()
 main.confirmation.canceled.emit()
 assert(game.state.cast and game.state.pending_catch.is_empty())
 assert(game.toggle_pause().ok and game.state.paused)
 main.refresh()
 assert(main.pause_button.text == '继续')
 assert(game.toggle_pause().ok and not game.state.paused)
 main.perform_fishing('reel')
 main.confirmation.hide()
 main.confirmation.confirmed.emit()
 assert(not game.state.cast and game.state.last_outcome == 'failed' and game.state.encyclopedia.is_empty())
 assert(game.set_duration(60).ok)
 main.perform_fishing('cast')
 main.ocean.skip()
 game.state.focus_seconds = 3600.0
 main.refresh()
 assert(main.status_title.text.contains('完成') and main.time_text.text == '00:00')
 main.perform_fishing('reel')
 assert(not game.state.pending_catch.is_empty())
 assert(game.model.species(game.state.pending_catch.species_id).focus_group == 'C')
 main.ocean.skip()
 main.open_collection('book')
 for group in ['A','B','C','event']:
  main.book_group = group
  main.panel_signature = ''
  main.render_collection()
  assert(main.collection_grid.get_child_count() == {'A':5,'B':5,'C':3,'event':1}[group])
 main.close_collection()
 main.layouts.apply('mini',false)
 main.layouts.sync_tools()
 assert(main.layouts.timer_label.text.contains('00:00') and main.layouts.action_buttons.reel.text == '安置鱼获')
 for suffix in ['', '.bak','.tmp']:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
 print('Pomodoro UI: duration, pause/resume, early failure cancel/confirm, successful C catch, grouped book and floating timer passed')
 quit()
