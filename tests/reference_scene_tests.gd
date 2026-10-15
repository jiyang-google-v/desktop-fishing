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
 assert(layouts.tools.size.x == 132 and layouts.tools.size.y >= 330)
 assert(layouts.view.rig_geometry().tip.x < layouts.view.rig_geometry().hand.x)
 var image := Image.load_from_file(ProjectSettings.globalize_path('res://assets/production/scene/reference-floating-environment.png'))
 assert(not image.is_empty() and image.detect_alpha() != Image.ALPHA_NONE)
 # Stable lower outline: small rock details remain, but no broad bowl-shaped base.
 var bottom_bands: Array[int] = []
 for band in 16:
  var bottoms: Array[int] = []
  var left: int = int(image.get_width()*(.10+band*.05))
  var right: int = int(image.get_width()*(.15+band*.05))
  for x in range(left,right):
   for y in range(image.get_height()-1,int(image.get_height()*.75),-1):
    if image.get_pixel(x,y).a >= .5:
     bottoms.append(y)
     break
  assert(not bottoms.is_empty())
  bottoms.sort()
  bottom_bands.append(bottoms[bottoms.size()/2])
 assert(bottom_bands.max()-bottom_bands.min() <= 18)
 assert(image.get_pixel(0,image.get_height()-1).a == 0.0)
 assert(image.get_pixel(image.get_width()-1,image.get_height()-1).a == 0.0)

 layouts.apply('mini',false)
 await process_frame
 assert(layouts.mode_grid.columns == 3 and layouts.action_grid.columns == 3)
 assert(layouts.tools.size == Vector2i(320,160))
 assert(layouts.view.rig_geometry().tip.x < layouts.view.rig_geometry().hand.x)
 print('Reference scenes: transparent environment, approved left-facing scene rig and adaptive vertical toolbar passed')
 quit()
