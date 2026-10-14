extends SceneTree
func _initialize() -> void:
 call_deferred('run')
func run() -> void:
 var main = load('res://scenes/main.tscn').instantiate()
 root.add_child(main)
 await process_frame
 var game = root.get_node('Game')
 var layouts = main.layouts
 game.save_path = 'user://card-test-'+game.model.new_id()+'.json'
 game.state = game.model.fresh_state()
 game.focus_status = {'supported':true,'locked':false}
 for mode in ['scene','mini']:
  layouts.apply(mode,false)
  await process_frame
  layouts.sync_tools()
  var card = layouts.timer_card
  assert(card.visible and card.pause_button.disabled)
  assert(card.status_label.text == '待放竿')
  assert(Rect2(Vector2.ZERO,Vector2(layouts.SIZES[mode])).encloses(card.get_rect()))
  game.model.cast_line(game.state)
  game.state.focus_seconds = 24.0
  layouts.sync_tools()
  assert(card.time_label.text == '24:36' and card.status_label.text == '专注中')
  assert(not card.pause_button.disabled)
  var position_before: Vector2i = root.position
  var event := InputEventMouseButton.new()
  event.button_index = MOUSE_BUTTON_LEFT
  event.pressed = true
  event.position = card.position+Vector2(10,10)
  layouts._input(event)
  assert(not layouts.drag and root.position == position_before)
  card.pause_button.pressed.emit()
  assert(game.state.paused and game.state.focus_seconds == 24.0)
  layouts.sync_tools()
  assert(card.status_label.text == '已暂停')
  var snapshot := JSON.stringify(game.state)
  layouts.apply('mini' if mode == 'scene' else 'scene',false)
  assert(JSON.stringify(game.state) == snapshot)
  layouts.timer_card.pause_button.pressed.emit()
  assert(not game.state.paused)
  game.state.focus_seconds = 1500.0
  layouts.sync_tools()
  assert(card.time_label.text == '00:00' and card.status_label.text == '专注完成')
  assert(card.pause_button.disabled and is_equal_approx(card.progress.value,1.0))
  card.sync(game,true)
  assert(card.day_icon.texture == card.MOON)
  card.sync(game,false)
  assert(card.day_icon.texture == card.SUN)
  game.state = game.model.fresh_state()
 layouts.apply('full',false)
 assert(not layouts.timer_card.visible)
 for suffix in ['', '.bak','.tmp']:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path+suffix))
 print('Card A: both layouts, status/time/progress, pause click, drag exclusion, state preservation and day/night passed')
 quit()
