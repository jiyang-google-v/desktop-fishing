extends SceneTree
const View = preload('res://scripts/ui/floating_art_view.gd')
var failures := 0
func check(value: bool, message: String) -> void:
 if not value:
  failures += 1
  push_error(message)
func _initialize() -> void:
 call_deferred('run')
func run() -> void:
 var manifest = JSON.parse_string(FileAccess.get_file_as_string('res://assets/production/floating_manifest.json'))
 check(manifest.assets.size() == 6,'Six separate floating layers')
 for asset in manifest.assets:
  var image := Image.load_from_file(ProjectSettings.globalize_path('res://'+asset.path))
  check(not image.is_empty() and image.get_size() == Vector2i(asset.size[0],asset.size[1]),'Native canvas preserved: '+asset.id)
  check(image.detect_alpha() != Image.ALPHA_NONE,'Actual alpha channel: '+asset.id)
 for entry in manifest.reused:
  for path in entry.get('frames',[entry.get('path','')]):
   check(FileAccess.file_exists('res://'+path),'Reused file exists: '+path)
 var view = View.new()
 root.add_child(view)
 await process_frame
 view.set_process(false)
 check(view.config.profiles.mini.allowed_art == ['rod','bobber','mini-water'],'Minimal art whitelist has no people, hand, pier or UI')
 for mode in ['scene','mini']:
  view.profile = mode
  for clip in ['idle','cast','reel','happy']:
   view.action = clip
   for t in [0.0,.35,.7]:
    view.age = t
    view.size = Vector2(600,400) if mode == 'scene' else Vector2(240,140)
    var rig: Dictionary = view.rig_geometry()
    check(is_equal_approx(rig.tip.x,rig.bobber.x),'Line and bobber vertically connected')
    check(rig.tip.x > rig.hand.x if mode == 'scene' else rig.tip.x < rig.hand.x,'Rod faces toward water in each layout')
 check(view.config.render_rules.transparent_clear,'No sky background rectangle')
 print('Floating production asset checks: failures=%d' % failures)
 quit(1 if failures else 0)
