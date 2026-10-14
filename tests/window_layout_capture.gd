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
 main.layouts.apply('mini',false)
 main.layouts.set_process(false)
 main.layouts.toolbar.show()
 main.layouts.show_tools()
 await process_frame
 await process_frame
 RenderingServer.force_draw()
 assert(main.layouts.tools.get_texture().get_image().save_png('res://docs/qa/layouts/hover-tools.png') == OK)
 main.layouts.tools.hide()
 main.layouts.view.night = true
 main.layouts.view.queue_redraw()
 await process_frame
 RenderingServer.force_draw()
 assert(root.get_texture().get_image().save_png('res://docs/qa/layouts/mini-night.png') == OK)
 print('Captured all three implemented main-window layouts and compact hover controls')
 quit()
