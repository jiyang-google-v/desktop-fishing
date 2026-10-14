extends SceneTree
const Flow = preload("res://scripts/core/scene_motion.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
 if not ok:
  failures += 1
  push_error(message)
func _initialize() -> void:
 var flow = Flow.new()
 check(flow.begin("cast"),"Start cast animation")
 check(not flow.begin("reel"),"Busy animation rejects duplicate action")
 flow.advance(0.4)
 check(flow.active == "cast" and flow.progress > 0,"Cast advances")
 flow.skip()
 check(not flow.busy(),"Skip finishes animation")
 check(flow.begin("reel"),"Can reel after cast")
 flow.advance(20)
 check(not flow.busy() and flow.progress == 1.0,"Long frame completes once")
 check(not flow.begin("unknown"),"Unknown animation rejected")
 var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/production/asset_manifest.json"))
 for asset in manifest.assets:
  check(FileAccess.file_exists("res://" + asset.path),"Asset exists " + asset.id)
 var model = preload("res://scripts/core/fishing_model.gd").new()
 var old_state: Dictionary = model.fresh_state()
 old_state.erase("sound_enabled")
 check(not model.restore(old_state).state.sound_enabled,"Legacy save starts muted")
 var sound_state: Dictionary = model.fresh_state()
 sound_state.sound_enabled = true
 check(model.restore(sound_state).state.sound_enabled,"Sound setting round trip")
 var config = JSON.parse_string(FileAccess.get_file_as_string("res://assets/production/scene.animation.json"))
 check(config.animations.cast.duration > 0 and config.animations.reel.duration > 0,"Real animation configuration")
 print("Stage 2 motion/resource tests: failures=%d" % failures)
 quit(1 if failures else 0)
