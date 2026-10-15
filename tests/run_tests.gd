extends SceneTree
const Model = preload('res://scripts/core/fishing_model.gd')
const Store = preload('res://scripts/core/save_store.gd')
const Sample = preload('res://scripts/core/focus_sample.gd')
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(message)
func _initialize() -> void:
 call_deferred('run')
func run() -> void:
 var m = Model.new()
 var rng := RandomNumberGenerator.new()
 rng.seed = 42
 check(m.roster.size() == 14 and m.roster[10].id == 'fish_011_lanternfish','Stable species IDs')
 var s: Dictionary = m.fresh_state()
 check(s.version == 4,'Save version 4')
 check(m.cast_line(s).ok,'Start')
 s.focus_seconds = 60
 check(not m.cast_line(s).ok and s.focus_seconds == 60,'Duplicate start preserves challenge')
 var before := s.duplicate(true)
 check(not m.reel_line(s,12,rng).ok and s == before,'Early reel preserves challenge before confirmation')
 s.focus_seconds = s.duration_minutes*60.0
 check(m.reel_line(s,12,rng).ok,'Completed reel')
 var catch_copy := s.duplicate(true)
 check(not m.reel_line(s,12,rng).ok and s == catch_copy,'Duplicate reel preserves fish')
 check(not m.cast_line(s).ok,'Pending blocks next challenge')
 check(m.settle(s,'keep').ok and s.aquarium.size() == 1,'Keep')
 check(not m.settle(s,'keep').ok,'No double claim')
 m.cast_line(s)
 s.focus_seconds = s.duration_minutes*60.0
 m.reel_line(s,12,rng)
 for i in 5:
  var c: Dictionary = s.pending_catch.duplicate(true)
  c.catch_id = 'existing-'+str(i)
  s.aquarium.append(c)
 var full := s.duplicate(true)
 check(not m.settle(s,'keep').ok and s == full,'Full tank preserves both')
 check(not m.settle(s,'replace','missing').ok and s == full,'Invalid replacement preserves both')
 var target: String = s.aquarium[2].catch_id
 var incoming: String = s.pending_catch.catch_id
 check(m.settle(s,'replace',target).ok and s.aquarium.size() == 6 and s.aquarium[2].catch_id == incoming,'Replace exactly one')
 var book: Dictionary = s.encyclopedia.duplicate(true)
 check(m.remove_from_tank(s,incoming).ok and s.encyclopedia == book,'Release retains book')
 check(m.restore(s).state == s,'Settled state round trip')
 m.cast_line(s)
 s.focus_seconds = 45.0
 s.paused = true
 s.pause_cause = 'manual'
 check(m.restore(s).state == s,'Paused timer round trip')
 var old := s.duplicate(true)
 old.version = 3
 old.aquarium.append({'catch_id':'star-old','species_id':'fish_012_star_wish_fish','length_cm':18.0})
 old.encyclopedia['fish_012_star_wish_fish'] = {'count':1,'record_cm':18.0}
 var migration: Dictionary = m.restore(old)
 check(migration.ok and not migration.state.cast and migration.state.focus_seconds == 0,'Legacy dive resets')
 check(migration.state.encyclopedia == old.encyclopedia and migration.state.aquarium.back().species_id == 'fish_012_star_wish_fish','Migration preserves event collection')
 var legacy: Dictionary = m.restore({'version':1,'aquarium':['fish_011_lanternfish'],'encyclopedia':{},'focusSeconds':100})
 check(legacy.ok and legacy.state.aquarium[0].species_id == 'fish_011_lanternfish','Legacy v1 migration')
 check(not m.restore({'version':999}).ok,'Unknown version blocked')
 check(not m.restore({'version':4}).ok,'Incomplete current save rejected')
 for bad in [-1,14,121,25.5,'25']:
  var invalid := m.fresh_state()
  invalid.duration_minutes = bad
  check(not m.restore(invalid).ok,'Corrupt duration rejected '+str(bad))
 var sample := {'token':'test','supported':true,'foreground':false,'locked':false,'idle_seconds':0,'sampled_at':100.0,'sequence':2,'epoch':1}
 check(not Sample.validate(sample,'test',101).is_empty(),'Valid safety sample')
 for field in sample:
  var invalid := sample.duplicate()
  invalid.erase(field)
  check(Sample.validate(invalid,'test',101).is_empty(),'Missing safety field '+field)
 check(Sample.validate(sample,'wrong',101).is_empty(),'Foreign worker rejected')
 check(Sample.validate(sample,'test',104).is_empty(),'Stale safety data rejected')
 check(Sample.validate(sample,'test',99).is_empty(),'Future data rejected')
 var store = Store.new()
 var path: String = 'user://test-save-'+m.new_id()+'.json'
 var saved: Dictionary = m.fresh_state()
 saved.focus_seconds = 42
 check(store.write(path,saved).ok,'Write primary')
 saved.focus_seconds = 80
 check(store.write(path,saved).ok,'Rotate backup')
 check(store.read(path,m).state.focus_seconds == 80,'Read latest')
 var broken := FileAccess.open(path,FileAccess.WRITE)
 broken.store_string('{broken')
 broken.close()
 var recovered: Dictionary = store.read(path,m)
 check(recovered.ok and recovered.recovered and recovered.state.focus_seconds == 42,'Recover backup')
 broken = FileAccess.open(path,FileAccess.WRITE)
 broken.store_string('{"version":4}')
 broken.close()
 check(store.read(path,m).recovered,'Incomplete primary uses backup')
 check(store.write(path,recovered.state).ok,'Repair primary')
 check(store.read(path+'.bak',m).state.focus_seconds == 42,'Preserve healthy backup')
 var game = root.get_node('Game')
 game.save_path = path
 game.state = m.fresh_state()
 check(game.set_duration(45).ok and game.state.duration_minutes == 45,'Duration transaction')
 check(not game.set_duration(121).ok,'Invalid duration transaction')
 check(game.cast_line().ok,'Start persisted')
 check(not game.set_duration(60).ok and game.state.duration_minutes == 45,'Active target frozen')
 game.focus_status = {'supported':true,'locked':false}
 check(game.toggle_pause().ok and game.state.paused,'Pause persisted')
 check(game.prepare_exit(),'Exit saves')
 check(store.read(path,m).state == game.state,'Exact state saved')
 var previous: Dictionary = game.state.duplicate(true)
 game.save_path = 'user://missing-'+m.new_id()+'/save.json'
 check(not game.fail_challenge().ok and game.state == previous,'Failed save cannot end challenge')
 check(not game.prepare_exit() and game.save_failed,'Save failure cancels exit')
 game.save_path = path
 check(game.prepare_exit() and not game.save_failed,'Recover save')
 check(game.fail_challenge().ok and game.state.last_outcome == 'failed','Confirmed failure persisted')
 game.blocked = true
 check(game.prepare_exit(),'Blocked save exits without overwrite')
 game.blocked = false
 for suffix in ['', '.bak','.tmp']:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
 var future := FileAccess.open(path,FileAccess.WRITE)
 future.store_string('{"version":999}')
 future.close()
 check(not store.read(path,m).ok and not store.write(path,m.fresh_state()).ok,'Future save protected')
 DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
 print('Pomodoro model/storage checks: %d, failures: %d' % [checks,failures])
 quit(1 if failures else 0)
