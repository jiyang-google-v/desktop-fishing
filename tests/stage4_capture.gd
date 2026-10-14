extends SceneTree
const Ocean = preload("res://scripts/ui/ocean_view.gd")
func _initialize() -> void:
 call_deferred("capture")
func capture() -> void:
 OS.low_processor_usage_mode = false
 root.size = Vector2i(960,760)
 root.content_scale_size = Vector2i(960,760)
 var view = Ocean.new()
 root.add_child(view)
 view.size = Vector2(912,684)
 view.position = Vector2(24,52)
 view.set_process(false)
 view.night = false
 view.working = true
 view.depth = 80
 var title := Label.new()
 title.text = "V2.6 · 放钩 → 安静等待 → 收杆 → 伙伴的反应（固定测试数据）"
 title.position = Vector2(24,15)
 title.add_theme_color_override("font_color",Color("496775"))
 root.add_child(title)
 var folder := "user://stage4-frames"
 DirAccess.make_dir_recursive_absolute(folder)
 view.play("cast")
 for i in range(60):
  if i == 13:
   view.cast = true
  if i == 20:
   view.play("reel")
   view.cast = false
   view.depth = 0
   view.show_catch(true)
  view._process(.1)
  view.queue_redraw()
  await process_frame
  RenderingServer.force_draw()
  root.get_texture().get_image().save_png(folder+"/frame-%03d.png"%i)
 print("Stage 4 integrated 60-frame sequence: "+ProjectSettings.globalize_path(folder))
 quit()
