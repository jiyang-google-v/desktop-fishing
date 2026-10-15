extends SceneTree
func _initialize() -> void:
 call_deferred('run')
func run() -> void:
 var main = load('res://scenes/main.tscn').instantiate()
 root.add_child(main)
 await process_frame
 var game = root.get_node('Game')
 var layouts = main.layouts
 layouts.test_mode=false
 layouts.settings.set_value('window','mode','mini')
 assert(layouts.startup_mode()=='scene')
 layouts.test_mode=true
 game.save_path='user://catch-zoom-tests.json'
 for mode in ['scene','mini']:
  game.state=game.model.fresh_state()
  layouts.apply(mode,false)
  layouts.sync_tools()
  assert(not layouts.timer_card.pause_button.disabled)
  layouts.timer_card.pause_button.pressed.emit()
  assert(game.state.cast and main.ocean.motion.active=='cast')
  var session: String = game.state.session_id
  layouts.timer_card.pause_button.pressed.emit()
  assert(game.state.session_id==session,'A repeated start click does not recast')
  main.ocean.skip()
  var state := JSON.stringify(game.state)
  layouts.set_zoom(1.5)
  assert(root.size==Vector2i(Vector2(layouts.SIZES[mode])*1.5),'scaled size %s zoom %s area %s' % [root.size,layouts.zoom_factor(),DisplayServer.screen_get_usable_rect()])
  assert(root.content_scale_size==layouts.SIZES[mode])
  assert(JSON.stringify(game.state)==state)
  layouts.apply('full',false)
  layouts.apply(mode,false)
  assert(is_equal_approx(layouts.zoom_factor(),1.5))
  layouts.set_zoom(100)
  assert(layouts.zoom_factor()<=2.0)
  layouts.set_zoom(-100)
  assert(layouts.zoom_factor()>=.75)
  layouts.set_zoom(1)
  layouts.view.line_cast=true
  layouts.view.action='idle'
  if mode=='mini':
   var rig: Dictionary=layouts.view.rig_geometry()
   assert(is_equal_approx(rig.tip.x,rig.bobber.x) and rig.tip.y<rig.bobber.y)
  game.state.focus_seconds=game.state.duration_minutes*60.0
  main.perform_fishing('reel')
  main.ocean.skip()
  layouts.sync_catch()
  var popup=layouts.catch_popup
  assert(popup.fish.fit_visible and popup.fish.custom_minimum_size.y>=200)
  assert(not popup.knowledge.text.is_empty())
  assert(popup.keep_button.get_parent()==popup.later_button.get_parent())
  main.open_collection('tank')
  await process_frame
  assert(main.aquarium_view.visible and main.aquarium_view.size_flags_vertical==Control.SIZE_EXPAND_FILL)
  main.close_collection()
  for f in game.model.roster:
   var intro: Dictionary=popup.introductions[f.id]
   assert(not intro.habitat.contains('分钟') and not intro.fact.is_empty())
   assert(not intro.sources.is_empty() or f.focus_group=='event')
  layouts.sync_tools()
  assert(layouts.timer_card.pause_button.disabled,'A pending catch cannot start a second cast')
  popup.settle('keep')
 for suffix in ['', '.bak','.tmp']:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path+suffix))
 main.scene_audio.set_enabled(false)
 main.queue_free()
 await process_frame
 print('Catch card encyclopedia, timer-start cast, saved bounded zoom, and vertical mini line passed')
 quit()
