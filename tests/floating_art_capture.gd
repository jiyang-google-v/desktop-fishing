extends SceneTree
const View = preload('res://scripts/ui/floating_art_view.gd')
func _initialize() -> void:
 call_deferred('capture')
func option(prefix: String, fallback: String) -> String:
 for value in OS.get_cmdline_user_args():
  if value.begins_with(prefix+'='):
   return value.substr(prefix.length()+1)
 return fallback
func capture() -> void:
 var mode: String = option('--profile','scene')
 var backdrop: String = option('--backdrop','light')
 var pose: String = option('--pose','idle')
 var target_size := Vector2i(600,400) if mode == 'scene' else Vector2i(240,140)
 root.size = target_size
 root.content_scale_size = target_size
 root.transparent_bg = backdrop == 'transparent'
 var bg := ColorRect.new()
 bg.size = target_size
 bg.color = Color('edf2ed') if backdrop == 'light' else (Color('27343c') if backdrop == 'dark' else Color.TRANSPARENT)
 root.add_child(bg)
 var view = View.new()
 view.profile = mode
 view.action = pose
 view.night = '--night' in OS.get_cmdline_user_args()
 view.size = target_size
 root.add_child(view)
 view.set_process(false)
 view.age = .35
 view.queue_redraw()
 await process_frame
 await process_frame
 RenderingServer.force_draw()
 var suffix := '-night' if view.night else ''
 var destination := 'res://docs/qa/floating/%s-%s-%s%s.png' % [mode,backdrop,pose,suffix]
 var image := root.get_texture().get_image()
 assert(image.save_png(destination) == OK)
 print('Captured '+destination)
 quit()
