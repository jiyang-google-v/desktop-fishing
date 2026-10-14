extends SceneTree
func _initialize() -> void:
 call_deferred('run')
func run() -> void:
 var main = load('res://scenes/main.tscn').instantiate()
 root.add_child(main)
 await process_frame
 DirAccess.make_dir_recursive_absolute('res://docs/qa/layouts')
 for mode in ['full','scene','mini']:
  main.layouts.apply(mode,false)
  main.layouts.toolbar.hide()
  await process_frame
  await process_frame
  RenderingServer.force_draw()
  var image := root.get_texture().get_image()
  assert(image.save_png('res://docs/qa/layouts/'+mode+'.png') == OK)
 print('Captured all three implemented main-window layouts')
 quit()
