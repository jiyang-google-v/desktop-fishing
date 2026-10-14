extends SceneTree
const Frames = preload("res://scripts/core/motion_frames.gd")
const Ocean = preload("res://scripts/ui/ocean_view.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
 if not ok:
  failures += 1
  push_error(message)
func _initialize() -> void:
 var frames = Frames.new()
 check(frames.frame_index("fisher", "cast", -1) == 0, "Negative time starts at frame zero")
 check(frames.frame_index("fisher", "cast", 100) == 5, "One-shot action holds final pose")
 check(frames.frame_index("fisher", "idle", 3.2) == 0, "Idle loops at exact boundary")
 check(frames.frame_index("cat", "blink", 100) == 3, "Blink completes and holds final open eyes")
 check(frames.frame_index("fx", "splash", .001) == 0, "Splash begins at its first frame")
 check(frames.frame_index("fx", "splash", .95) == 7, "Splash finishes before returning to ripple")
 check(frames.frame_index("missing", "missing", 0) == -1, "Unknown animation has safe empty result")
 var totals := {"fisher":22,"cat":16,"fx":34}
 for group in totals:
  var count := 0
  for clip in frames.config.groups[group].clips:
   var sequence: Dictionary = frames.config.groups[group].clips[clip]
   count += sequence.frames.size()
   for path in sequence.frames:
    check(ResourceLoader.exists("res://" + path), "Exported frame exists " + path)
   check(frames.texture(group, clip, 0) != null, "Runtime can load " + group + "/" + clip)
  check(count == totals[group], "Complete frame inventory " + group)
 var flow = preload("res://scripts/core/scene_motion.gd").new()
 check(is_equal_approx(frames.duration("fisher","cast"),float(flow.config.animations.cast.duration)), "Cast artwork and input lock share duration")
 check(is_equal_approx(frames.duration("fisher","reel"),float(flow.config.animations.reel.duration)), "Reel artwork and input lock share duration")
 for viewport in [Vector2(480,500),Vector2(720,600),Vector2(912,684)]:
  var unit: float = minf(viewport.x,viewport.y)
  var actor: float = unit*.33
  var origin_y: float = viewport.y*.28-3*unit/1000-.71*actor
  for clip in frames.config.groups.fisher.clips:
   var item: Dictionary = frames.sequence("fisher",clip)
   for i in item.frames.size():
    var seconds: float = (i+.5)/item.frames.size()*float(item.duration)
    var hand_y: float = origin_y+frames.grip(clip,seconds).y*actor
    var angle: float = frames.fitted_rod_rotation(clip,seconds,hand_y,unit*.38,14*unit/1000)
    var tip_y: float = hand_y+Vector2(.71,-.64).rotated(angle).y*unit*.38
    check(tip_y >= 14*unit/1000-.01,"Rod tip stays inside responsive scene: "+clip)
 var ocean = Ocean.new()
 for depth in [0.0,50.0,200.0]:
  var bobber := Vector2(300,200)
  var hook := Vector2(300,200+depth)
  var line: PackedVector2Array = ocean.fishing_line_points(Vector2(120,80),bobber,hook,true,.7,1.0)
  check(line.size() == 31,"Split fishing line includes a stable float attachment point")
  check(line[15].distance_to(bobber) < .01,"Fishing line meets the bobber")
  check(line[line.size()-1].distance_to(hook) < .01,"Fishing line reaches the hook")
  for i in range(15,line.size()):
   check(absf(line[i].x-bobber.x) < .01,"Line below the bobber hangs vertically at depth %dm" % int(depth))
 ocean.free()
 print("Stage 4 visual motion checks: failures=%d" % failures)
 quit(1 if failures else 0)
