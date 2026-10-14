extends SceneTree
func _initialize() -> void:
 call_deferred('run')
func run() -> void:
 var main = load('res://scenes/main.tscn').instantiate()
 root.add_child(main)
 await process_frame
 DirAccess.make_dir_recursive_absolute('res://docs/qa/window-frame')
 main.layouts.apply('full',false)
 for i in 6:
  await process_frame
 RenderingServer.force_draw()
 var image: Image = root.get_texture().get_image()
 assert(image.save_png('res://docs/qa/window-frame/full.png') == OK)
 assert(image.get_region(Rect2i(0,0,image.get_width(),36)).save_png('res://docs/qa/window-frame/titlebar.png') == OK)
 assert(main.layouts.frame.buttons.close.get_global_rect().end.x <= root.size.x)
 print('Captured full window and custom titlebar at actual dimensions')
 quit()
