extends SceneTree

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
