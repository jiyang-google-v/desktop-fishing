extends SceneTree
const Scene = preload('res://scripts/ui/mode2_scene.gd')
func _initialize() -> void:
 call_deferred('run')
func run() -> void:
 var main = load('res://scenes/main.tscn').instantiate()
 root.add_child(main)
 await process_frame
 main.layouts.apply('scene',false)
 await process_frame
 var view = main.layouts.view.mode2_view
 assert(view is Scene)
 view.set_process(false)
 # Every swimmer travels one way through its lifetime; no turn animation.
 view.spawn_fish(1,0,0.0)
 view.spawn_fish(-1,1,0.0)
 var a: Dictionary = view.fish_events[-2]
 var b: Dictionary = view.fish_events[-1]
 assert(view.fish_x(a,1.0)>view.fish_x(a,0.0))
 assert(view.fish_x(b,1.0)<view.fish_x(b,0.0))
 assert(view.layer_order == ['water','far_fish','mid_plants','near_fish','front_plants','coral','pier','actors','surface','catch'])
 view.line_cast = false
 view.action = 'idle'
 var rig: Dictionary = view.rig_geometry()
 assert(rig.tip.distance_to(rig.bobber)<30.0)
 view.line_cast = true
 rig = view.rig_geometry()
 assert(absf(rig.bobber.y-429.0)<2.0)
 assert(rig.tip.x<rig.hand.x)
 for e in view.asset_manifest.assets:
  var image = Image.load_from_file(ProjectSettings.globalize_path('res://'+e.path))
  assert(not image.is_empty() and image.detect_alpha()!=Image.ALPHA_NONE)
 var popup = main.layouts.catch_popup
 for t in [1.9,2.2,3.5,8.0]:
  var geometry: Dictionary = popup.reveal_geometry(t)
  assert(geometry.scale==Vector2.ONE and geometry.offset==Vector2.ZERO)
 print('Mode2 v5: directional paths, water layers, short-line state, alpha assets, stationary revealed card passed')
 quit()
