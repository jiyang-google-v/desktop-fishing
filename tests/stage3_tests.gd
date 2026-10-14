extends SceneTree
const Model = preload("res://scripts/core/fishing_model.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
 if not ok:
  failures += 1
  push_error(message)
func _initialize() -> void:
 var m = Model.new()
 var s: Dictionary = m.fresh_state()
 var rng := RandomNumberGenerator.new()
 rng.seed = 44
 m.cast_line(s)
 m.reel_line(s,12,rng)
 check(s.pending_catch.get("first_discovery",false),"First catch discovery flag")
 check(s.pending_catch.get("new_record",false),"First catch record flag")
 check(m.restore(s).state == s,"Pending celebration survives restore")
 var c: Dictionary = s.pending_catch
 var id: String = c.species_id
 check(not m.reel_line(s,12,rng).ok,"Repeated reel cannot replace saved flags")
 m.settle(s,"release")
 for f in m.roster:
  s.encyclopedia[f.id] = {"count":4,"record_cm":1000.0}
 m.cast_line(s)
 m.reel_line(s,12,rng)
 check(not s.pending_catch.first_discovery and not s.pending_catch.new_record,"Existing species below record is not celebrated")
 s.pending_catch.first_discovery = true
 s.pending_catch.new_record = true
 var old: Dictionary = s.duplicate(true)
 old.pending_catch.erase("first_discovery")
 old.pending_catch.erase("new_record")
 check(not m.restore(old).state.pending_catch.get("first_discovery",false),"Legacy catch does not invent discovery")
 var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/production/collection_manifest.json"))
 check(manifest.assets.size() == 14,"Complete stable fourteen species")
 for asset in manifest.assets:
  check(not m.species(asset.id).is_empty(),"Stable sample species")
  check(FileAccess.file_exists("res://"+asset.path),"Sample exists")
  var texture = load("res://"+asset.path) as Texture2D
  check(texture != null and texture.get_size() == Vector2(1254,1254),"Unified sample canvas")
 var config = JSON.parse_string(FileAccess.get_file_as_string("res://assets/production/collection.animation.json"))
 check(config.swim.duration > 0 and config.drift.duration > 0,"Valid movement timing")
 for special_id in ["fish_004_seahorse","creature_013_jellyfish","creature_014_cuttlefish"]:
  check(config.species.has(special_id),"Special species movement is configured")
 var layers = JSON.parse_string(FileAccess.get_file_as_string("res://assets/production/aquarium_manifest.json"))
 check(layers.assets.size() == 3,"Three independent aquarium layers")
 for layer in layers.assets:
  check(FileAccess.file_exists("res://"+layer.path),"Aquarium layer exists")
 print("Stage 3 collection checks: failures=%d" % failures)
 quit(1 if failures else 0)
