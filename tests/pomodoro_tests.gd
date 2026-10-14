extends SceneTree
const Model = preload('res://scripts/core/fishing_model.gd')
var failures := 0
func check(value: bool, message: String) -> void:
 if not value:
  failures += 1
  push_error(message)
func _initialize() -> void:
 call_deferred('run')
func run() -> void:
 var m = Model.new()
 var rng := RandomNumberGenerator.new()
 rng.seed = 123
 for minutes in [15,25,29,30,45,59,60,120]:
  var s: Dictionary = m.fresh_state()
  check(m.set_duration(s,minutes).ok,'Allowed duration '+str(minutes))
  check(m.cast_line(s).ok,'Begin timer')
  check(not m.set_duration(s,25).ok,'Duration frozen during challenge')
  s.focus_seconds = minutes*60-1
  var before := s.duplicate(true)
  check(not m.reel_line(s,12,rng).ok and s == before,'Early reel cannot generate or end before confirmation')
  s.focus_seconds = minutes*60
  check(m.reel_line(s,12,rng).ok and not s.pending_catch.is_empty(),'Completed challenge guaranteed catch')
  check(m.species(s.pending_catch.species_id).focus_group == m.group_for(minutes),'Exclusive group')
  check(s.pending_catch.duration_minutes == minutes,'Declared duration stored on catch')
 for minutes in [0,14,121,1000]:
  check(not m.set_duration(m.fresh_state(),minutes).ok,'Reject invalid duration')
 var failed: Dictionary = m.fresh_state()
 m.cast_line(failed)
 failed.focus_seconds = 60
 check(m.fail_challenge(failed).ok and not failed.cast and failed.pending_catch.is_empty() and failed.encyclopedia.is_empty(),'Early confirmed failure has no reward')
 for minutes in [25,45,60]:
  var pool: Array = m.fish_pool(minutes)
  check(pool.size() == (5 if minutes < 60 else 3),'Pool size')
  var sum := 0.0
  for f in pool:
   sum += m.fish_probability(f.id,minutes)
  check(is_equal_approx(sum,1),'Pool probability sum')
  for i in 300:
   var s: Dictionary = m.fresh_state()
   m.set_duration(s,minutes)
   m.cast_line(s)
   s.focus_seconds = minutes*60
   m.reel_line(s,0 if i%2 else 12,rng)
   check(m.species(s.pending_catch.species_id).focus_group == m.group_for(minutes),'No cross-group or event fish, all hours')
 check(is_equal_approx(m.fish_probability('fish_008_yellowfin_tuna',60),.6),'C 60 percent tuna')
 check(m.fish_probability('fish_012_star_wish_fish',120) == 0,'Star wish event only')
 var old: Dictionary = m.fresh_state()
 old.version = 3
 old.cast = true
 old.focus_seconds = 900
 old.session_id = 'legacy-session'
 var restored: Dictionary = m.restore(old)
 check(restored.ok and not restored.state.cast and restored.state.focus_seconds == 0,'Legacy active dive resets safely')
 var game = root.get_node('Game')
 game.state = m.fresh_state()
 m.cast_line(game.state)
 game.focus_status = {'supported':true,'locked':false,'foreground':true,'idle_seconds':99999}
 check(game.pause_reason() == 'working','Foreground and no input still count')
 game.state.paused = true
 check(game.pause_reason() == 'paused','Manual pause')
 game.state.paused = false
 game.advance_timer(1,1,{'supported':true,'locked':false})
 check(game.state.focus_seconds == 1,'Active timer advances')
 game.advance_timer(3600,3600,{'supported':true,'locked':false})
 check(game.state.paused and game.state.focus_seconds == 1,'Sleep gap pauses with no backfill')
 game.state.paused = false
 game.advance_timer(1,1,{'supported':true,'locked':true})
 check(game.state.paused and game.state.pause_cause == 'locked' and game.state.focus_seconds == 1,'Lock pauses')
 game.advance_timer(1,1,{'supported':true,'locked':false})
 check(game.state.paused and game.state.focus_seconds == 1,'Unlock requires manual resume')
 game.state = m.fresh_state()
 m.cast_line(game.state)
 game.state.focus_seconds = 123.0
 game.prepare_restored_challenge()
 check(game.state.paused and game.state.focus_seconds == 123.0 and game.state.pause_cause == 'restart','Restart pauses without offline credit')
 game.state.focus_seconds = game.state.duration_minutes*60.0
 game.state.paused = false
 game.prepare_restored_challenge()
 check(m.completed(game.state) and not game.state.paused,'Completed timer survives restart as claimable')
 print('Pomodoro rules and 900 exclusive-pool draws: failures=%d' % failures)
 quit(1 if failures else 0)
