extends SceneTree

const Policy = preload("res://scripts/core/focus_policy.gd")
const Sample = preload("res://scripts/core/focus_sample.gd")
const Model = preload("res://scripts/core/fishing_model.gd")
const Clock = preload("res://scripts/core/focus_clock.gd")
const Store = preload("res://scripts/core/save_store.gd")
var checks := 0
var failures := 0

func check(condition: bool, message: String) -> void:
 checks += 1
 if not condition:
  failures += 1
  push_error(message)

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var m = Model.new()
 check(m.roster.size() == 14, "Stable 14 species")
 check(m.roster[10].id == "fish_011_lanternfish", "Stable fish IDs")
 check(m.depth_for(60.0) == 4.0, "4m per minute")
 check(m.depth_for(6000.0) == 200.0, "Depth cap")
 var conditions = {"supported":true,"foreground":false,"locked":false,"idle_seconds":30.0}
 check(m.can_accrue(conditions), "Background active input")
 for field in ["foreground", "locked"]:
  var changed = conditions.duplicate()
  changed[field] = true
  check(not m.can_accrue(changed), "Pause: " + field)
 conditions.idle_seconds = 601.0
 check(not m.can_accrue(conditions), "Idle pause")
 conditions.idle_seconds = -1.0
 check(not m.can_accrue(conditions), "Invalid idle")
 check(not m.eligible_fish(190.0,false).any(func(f): return f.id == "fish_012_star_wish_fish"), "Night fish unavailable by day")
 check(m.eligible_fish(190.0,true).any(func(f): return f.id == "fish_012_star_wish_fish"), "Night fish available at night")
 var s: Dictionary = m.fresh_state()
 check(m.cast_line(s).ok, "Cast")
 s.focus_seconds = 60.0
 check(not m.cast_line(s).ok and s.focus_seconds == 60.0, "Duplicate cast preserves progress")
 var rng = RandomNumberGenerator.new()
 rng.seed = 42
 check(m.reel_line(s,12,rng).ok, "Reel")
 var locked_result: Dictionary = s.duplicate(true)
 check(not m.reel_line(s,12,rng).ok and s == locked_result, "Duplicate reel preserves result")
 check(not m.cast_line(s).ok, "Pending catch blocks cast")
 check(m.settle(s,"keep").ok and s.aquarium.size() == 1, "Keep individual")
 check(not m.settle(s,"keep").ok and s.aquarium.size() == 1, "Cannot claim twice")
 m.cast_line(s)
 m.reel_line(s,12,rng)
 for i in range(5):
  var c: Dictionary = s.pending_catch.duplicate(true)
  c.catch_id = "existing-%d" % i
  s.aquarium.append(c)
 var full: Dictionary = s.duplicate(true)
 check(not m.settle(s,"keep").ok and s == full, "Full tank preserves both")
 check(not m.settle(s,"replace","missing").ok and s == full, "Invalid replacement preserves both")
 var target: String = s.aquarium[2].catch_id
 var incoming: String = s.pending_catch.catch_id
 check(m.settle(s,"replace",target).ok and s.aquarium.size() == 6 and s.aquarium[2].catch_id == incoming, "Replace exactly one")
 var book: Dictionary = s.encyclopedia.duplicate(true)
 check(m.remove_from_tank(s,incoming).ok and s.encyclopedia == book, "Release retains book")
 var restored: Dictionary = m.restore(s)
 check(restored.ok and restored.state == s, "Restore locked/settled state")
 m.cast_line(s)
 s.focus_seconds = 45.0
 check(m.restore(s).state == s, "Restore active cast")
 check(not m.restore({"version":999}).ok, "Unknown version blocked")
 var legacy: Dictionary = m.restore({"version":1,"aquarium":["fish_011_lanternfish"],"encyclopedia":{},"focusSeconds":100})
 check(legacy.ok and legacy.state.aquarium[0].species_id == "fish_011_lanternfish", "Legacy migration")
 var pending: Dictionary = m.fresh_state()
 m.cast_line(pending)
 m.reel_line(pending,12,rng)
 check(m.restore(pending).state == pending, "Restore unrevealed individual")
 var old_book: Dictionary = pending.encyclopedia.duplicate(true)
 check(m.settle(pending,"release").ok and pending.encyclopedia == old_book, "Release pending preserves discovery")
 var clock = Clock.new()
 check(clock.advance(1,1,true,1) == 0, "First focus sample does not backfill")
 check(clock.advance(1,1,true,2) == 1, "Continuous focus accrues")
 check(clock.advance(1,1,false,3) == 0, "Foreground/locked/idle pauses")
 check(clock.advance(1,1,true,4) == 0, "Resume does not backfill")
 check(clock.advance(1,1,true,5) == 1, "Resume continuous accrual")
 check(clock.advance(1,3600,true,6) == 0, "Sleep wall-clock gap excluded")
 clock.reset()
 check(clock.advance(1,1,true,7) == 0, "Session/focus reset drops in-flight interval")
 check(clock.advance(1,1,true,7) == 0, "Repeated native sample does not accrue")
 check(clock.advance(1,1,true,8) == 0, "Require continuity after repeated sample")
 check(clock.advance(1,1,true,9) == 1, "New continuous samples resume")
 check(clock.advance(1,1,true,2) == 0, "Native sequence rollback pauses")
 check(clock.advance(1,1,true,3) == 0, "Rollback requires fresh continuity")
 check(not m.restore({"version":3}).ok, "Incomplete current save is corrupt")
 var game = root.get_node("Game")
 game.state = m.fresh_state()
 m.cast_line(game.state)
 game.focus_status = {"supported":false,"foreground":true,"locked":true,"idle_seconds":-1}
 check(game.pause_reason() == "unsupported", "Detection error is not hidden by foreground fallback")
 var test_state: Dictionary = m.fresh_state()
 m.cast_line(test_state)
 var active := {"supported":true,"foreground":false,"locked":false,"idle_seconds":0}
 for minutes in [5,10,20]:
  test_state.idle_minutes = minutes
  active.idle_seconds = minutes * 60
  check(Policy.reason(test_state,active,false,false) == "working", "Idle exact boundary %d" % minutes)
  active.idle_seconds += 0.1
  check(Policy.reason(test_state,active,false,false) == "idle", "Idle pauses %d" % minutes)
  active.idle_seconds = 0
  check(Policy.reason(test_state,active,false,false) == "working", "Input resumes %d" % minutes)
 check(Policy.reason(test_state,active,false,true) == "foreground", "Any focused game UI pauses")
 active.locked = true
 check(Policy.reason(test_state,active,false,false) == "locked", "Lock reason")
 active.supported = false
 check(Policy.reason(test_state,active,false,true) == "unsupported", "Detection failure priority")
 check(Policy.reason(test_state,active,true,false) == "blocked", "Save block priority")
 var old_save: Dictionary = test_state.duplicate(true)
 old_save.erase("idle_minutes")
 check(m.restore(old_save).state.idle_minutes == 10, "Existing save defaults to 10 minutes")
 test_state.idle_minutes = 20
 check(m.restore(test_state).state.idle_minutes == 20, "Setting round trip")
 test_state.idle_minutes = 11
 check(m.restore(test_state).state.idle_minutes == 10, "Invalid setting falls back")
 var sample := {"token":"test","supported":true,"foreground":false,"locked":false,"idle_seconds":0,"sampled_at":100.0,"sequence":2,"epoch":1}
 check(not Sample.validate(sample,"test",101).is_empty(), "Valid native sample")
 for field in ["supported","foreground","locked","idle_seconds","sampled_at","sequence","epoch"]:
  var malformed: Dictionary = sample.duplicate()
  malformed.erase(field)
  check(Sample.validate(malformed,"test",101).is_empty(), "Missing native field " + field)
 check(Sample.validate(sample,"wrong",101).is_empty(), "Foreign worker token rejected")
 check(Sample.validate(sample,"test",104).is_empty(), "Stale native data rejected")
 check(Sample.validate(sample,"test",99).is_empty(), "Future data rejected")
 clock.reset()
 check(clock.advance(1,1,true,1,"a:1") == 0, "Worker first sample")
 check(clock.advance(1,1,true,2,"a:1") == 1, "Same epoch accrues")
 check(clock.advance(1,1,true,3,"a:2") == 0, "Missed intermediate lock/focus event breaks continuity")
 check(clock.advance(1,1,true,4,"b:2") == 0, "New worker breaks continuity")
 check(clock.advance(1,1,true,5,"b:2") == 1, "New worker resumes")
 check(clock.advance(1,-1,true,6,"b:2") == 0, "Clock rollback excluded")
 check(clock.advance(1,1,true,7,"b:2") == 0, "Clock rollback recovery not backfilled")
 check(clock.advance(3600,3600,true,8,"b:2") == 0, "Sleep gap excluded")
 check(clock.advance(1,1,true,9,"b:2") == 0, "Wake requires fresh interval")
 var store = Store.new()
 var test_path = "user://test-save-%s.json" % m.new_id()
 var saved: Dictionary = m.fresh_state()
 saved.focus_seconds = 42.0
 check(store.write(test_path,saved).ok, "Write primary")
 saved.focus_seconds = 80.0
 check(store.write(test_path,saved).ok, "Write backup")
 check(store.read(test_path,m).state.focus_seconds == 80.0, "Read latest")
 var broken = FileAccess.open(test_path,FileAccess.WRITE)
 broken.store_string("{broken")
 broken.close()
 var recovered: Dictionary = store.read(test_path,m)
 check(recovered.ok and recovered.recovered and recovered.state.focus_seconds == 42.0, "Recover backup")
 # A parseable but incomplete primary must not replace the healthy backup.
 broken = FileAccess.open(test_path,FileAccess.WRITE)
 broken.store_string('{"version":3}')
 broken.close()
 check(store.read(test_path,m).recovered, "Incomplete primary falls back to backup")
 check(store.write(test_path,recovered.state).ok, "Can repair corrupt primary")
 check(store.read(test_path + ".bak",m).state.focus_seconds == 42.0, "Healthy backup survives repair")
 game.save_path = test_path
 game.state = test_state.duplicate(true)
 var original_seconds = game.state.focus_seconds
 check(game.set_idle_minutes(5).ok and game.state.idle_minutes == 5 and game.state.focus_seconds == original_seconds, "Setting commits without losing session")
 check(not game.set_idle_minutes(7).ok and game.state.idle_minutes == 5, "Invalid setting not committed")
 check(game.prepare_exit(), "Exit saves active session")
 check(store.read(test_path,m).state == game.state, "Exit restores exact session")
 game.save_path = "user://missing-%s/save.json" % m.new_id()
 var before_failure: Dictionary = game.state.duplicate(true)
 check(not game.set_idle_minutes(20).ok and game.state == before_failure, "Save failure rolls back setting")
 check(not game.prepare_exit() and game.save_failed, "Save failure cancels exit")
 game.save_path = test_path
 check(game.prepare_exit() and not game.save_failed and game.warning.is_empty(), "Save recovers after transient failure")
 game.blocked = true
 check(game.prepare_exit(), "Corrupt save can exit without overwriting")
 game.blocked = false
 for suffix in ["", ".bak", ".tmp"]:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path + suffix))
 var future = FileAccess.open(test_path,FileAccess.WRITE)
 future.store_string('{"version":999}')
 future.close()
 check(not store.read(test_path,m).ok, "Future save blocked")
 check(not store.write(test_path,m.fresh_state()).ok, "Future save not overwritten")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
 print("Godot model/storage checks: %d, failures: %d" % [checks,failures])
 quit(1 if failures else 0)
