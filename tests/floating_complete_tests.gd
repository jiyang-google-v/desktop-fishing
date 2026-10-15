extends SceneTree
const Focus = preload('res://scripts/services/windows_focus.gd')
func _initialize() -> void:
 call_deferred('run')
func run() -> void:
 var probe = Focus.new()
 var now: float = Time.get_unix_time_from_system()
 probe.token = 'test-token'
 var sample := {'token':probe.token,'sequence':1,'epoch':1,'sampled_at':now,'supported':true,'foreground':false,'locked':false,'idle_seconds':0.0}
 assert(probe.consume(sample,now,1000).supported)
 assert(probe.consume(sample,now+.2,1200).supported,'A repeated fresh sample must not pause')
 assert(probe.consume(null,now+.4,1400).supported,'An atomic file replacement gap reuses the fresh sample')
 assert(probe.consume(null,now+4,5000).get('transient',false),'A short detection gap holds time without latching pause')
 assert(not probe.consume(null,now+12,13000).get('transient',true),'A real watchdog timeout still fails closed')
 probe.free()
 var game = root.get_node('Game')
 game.state = game.model.fresh_state()
 game.model.cast_line(game.state)
 game.advance_timer(1,1,{'supported':false,'locked':true,'transient':true})
 assert(not game.state.paused and game.state.focus_seconds==0)
 game.advance_timer(1,1,{'supported':true,'locked':false})
 assert(not game.state.paused and game.state.focus_seconds==1)
 game.advance_timer(1,-3600,{'supported':true,'locked':false})
 assert(not game.state.paused and game.state.focus_seconds==2,'Wall-clock corrections do not pause a monotonic timer')
 game.state = game.model.fresh_state()
 var main = load('res://scenes/main.tscn').instantiate()
 root.add_child(main)
 await process_frame
 game.save_path = 'user://floating-complete-tests.json'
 for mode in ['scene','mini']:
  main.layouts.apply(mode,false)
  await process_frame
  assert(main.layouts.action_buttons.has('settings'))
  main.layouts.open_settings()
  var panel = main.layouts.control_panel
  assert(panel.visible)
  panel.duration.value = 45
  assert(game.state.duration_minutes==45)
  panel.sound.pressed.emit()
  assert(game.state.sound_enabled)
  panel.sound.pressed.emit()
  panel.hide()
  main.perform_fishing('cast')
  main.ocean.skip()
  panel.sync()
  assert(not panel.duration.editable)
  game.state.focus_seconds = game.state.duration_minutes*60.0
  main.perform_fishing('reel')
  await process_frame
  main.layouts._process(0.0)
  assert(main.layouts.view.action=='reel')
  if mode=='mini':
   var rig: Dictionary = main.layouts.view.rig_geometry()
   assert(rig.tip.distance_to(rig.bobber)<35.0,'Mini reel stays short')
  main.ocean.skip()
  main.layouts.sync_catch()
  assert(main.layouts.catch_popup.visible)
  main.layouts.catch_popup.settle('keep')
  assert(game.state.pending_catch.is_empty())
  game.state = game.model.fresh_state()
 for suffix in ['', '.bak','.tmp']:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path+suffix))
 print('Floating complete: fresh sample reuse, transient hold, settings parity, mini catch and shared card passed')
 quit()
