extends SceneTree
func _initialize() -> void:
 call_deferred('run')
func run() -> void:
 var main = load('res://scenes/main.tscn').instantiate()
 root.add_child(main)
 await process_frame
 var layouts = main.layouts
 layouts.apply('scene',false)
 await process_frame
 assert(layouts.mode_grid.columns == 1 and layouts.action_grid.columns == 1)
 assert(layouts.tools.size.x == 104 and layouts.tools.size.y >= 330)
 assert(layouts.view.rig_geometry().tip.x > layouts.view.rig_geometry().hand.x)
 var image := Image.load_from_file(ProjectSettings.globalize_path('res://assets/production/scene/reference-floating-environment.png'))
 assert(not image.is_empty() and image.detect_alpha() != Image.ALPHA_NONE)
 layouts.apply('mini',false)
 await process_frame
 assert(layouts.mode_grid.columns == 3 and layouts.action_grid.columns == 3)
 assert(layouts.tools.size == Vector2i(320,160))
 assert(layouts.view.rig_geometry().tip.x < layouts.view.rig_geometry().hand.x)
 print('Reference scenes: transparent environment, right-facing scene rig and adaptive vertical toolbar passed')
 quit()
