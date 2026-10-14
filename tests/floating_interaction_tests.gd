extends SceneTree
func _initialize() -> void:
 call_deferred('run')
func run() -> void:
 var main = load('res://scenes/main.tscn').instantiate()
 root.add_child(main)
 await process_frame
 var game = root.get_node('Game')
 var layouts = main.layouts
 game.save_path = 'user://floating-actions-'+game.model.new_id()+'.json'
 game.state = game.model.fresh_state()
 layouts.pinned = true
 root.always_on_top = true
 for mode in ['scene','mini']:
  layouts.apply(mode,false)
  await process_frame
  assert(not layouts.toolbar.has_node('ToolbarTimer'))
  assert(layouts.tools.transient and not layouts.tools.always_on_top)
  assert(layouts.catch_popup.transient and not layouts.catch_popup.always_on_top)
  assert(layouts.action_buttons.has('cast') and layouts.action_buttons.has('opacity'))
  assert(not layouts.action_buttons.cast.disabled and layouts.action_buttons.reel.disabled)
  layouts.set_opacity_percent(45)
  assert(is_equal_approx(layouts.view.modulate.a,.45) and is_equal_approx(layouts.timer_card.modulate.a,.45))
  assert(is_equal_approx(layouts.toolbar.modulate.a,1.0))
  layouts.request_action('cast')
  await process_frame
  assert(game.state.cast and layouts.mode == mode)
  main.ocean.skip()
  layouts.sync_tools()
  assert(layouts.action_buttons.cast.disabled and not layouts.action_buttons.reel.disabled)
  layouts.tool_action('reel')
  assert(main.confirmation.visible)
  main.confirmation.hide()
  main.confirmation.canceled.emit()
  assert(game.state.cast)
  game.state.focus_seconds = game.state.duration_minutes*60.0
  layouts.tool_action('reel')
  assert(not game.state.pending_catch.is_empty())
  assert(not layouts.catch_popup.visible)
  main.ocean.skip()
  layouts.sync_catch()
  assert(layouts.catch_popup.visible and layouts.mode == mode)
  var id: String = game.state.pending_catch.catch_id
  var reveals: int = layouts.catch_popup.reveal_count
  layouts.sync_catch()
  assert(layouts.catch_popup.reveal_count == reveals)
  layouts.apply('mini' if mode == 'scene' else 'scene',false)
  layouts.sync_catch()
  assert(game.state.pending_catch.catch_id == id)
  assert(layouts.catch_popup.reveal_count == reveals)
  layouts.catch_popup.keep_button.pressed.emit()
  await process_frame
  assert(game.state.pending_catch.is_empty() and game.state.aquarium.size() > 0)
  layouts.sync_catch()
  assert(not layouts.catch_popup.visible)
  game.state = game.model.fresh_state()
 # Dismiss/reopen, full tank replacement, confirmation cancellation and failed save.
 layouts.apply('mini',false)
 game.state = game.model.fresh_state()
 game.model.cast_line(game.state)
 game.state.focus_seconds = game.state.duration_minutes*60.0
 game.model.reel_line(game.state,12,RandomNumberGenerator.new())
 main.ocean.skip()
 layouts.sync_catch()
 var pending: Dictionary = game.state.pending_catch.duplicate(true)
 layouts.catch_popup.later_button.pressed.emit()
 layouts.sync_catch()
 assert(not layouts.catch_popup.visible and game.state.pending_catch == pending)
 layouts.tool_action('reel')
 assert(layouts.catch_popup.visible)
 layouts.catch_popup.confirm_release()
 assert(main.confirmation.visible)
 main.confirmation.hide()
 main.confirmation.canceled.emit()
 layouts.sync_catch()
 assert(layouts.catch_popup.visible and game.state.pending_catch == pending)
 for i in 6:
  var existing: Dictionary = pending.duplicate(true)
  existing.catch_id = 'existing-%d' % i
  game.state.aquarium.append(existing)
 layouts.catch_popup.present(game)
 assert(layouts.catch_popup.keep_button.text == '选择替换')
 layouts.catch_popup.settle('keep')
 assert(main.collection.visible and main.replacing and game.state.pending_catch == pending)
 main.close_collection()
 var path: String = game.save_path
 game.save_path = 'user://missing-directory/catch.json'
 layouts.catch_popup.settle('release')
 assert(game.state.pending_catch == pending)
 game.save_path = path
 game.state = game.model.fresh_state()
 # Per-mode settings and more than one sequence of native tool-window changes.
 for i in 12:
  for mode in ['scene','mini','full']:
   layouts.apply(mode,false)
   await process_frame
   if mode != 'full':
    layouts.show_tools()
    assert(layouts.tools.visible and layouts.action_buttons.has('cast'))
    assert(not layouts.action_buttons.cast.disabled)
    assert(layouts.opacity_percent() == 45)
 layouts.set_opacity_percent(-500)
 assert(layouts.opacity_percent() >= 30)
 for suffix in ['', '.bak','.tmp']:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path+suffix))
 print('Floating actions: opacity, cast, early cancel, reveal once, switch preservation, keep and repeated input lifecycle passed')
 quit()
