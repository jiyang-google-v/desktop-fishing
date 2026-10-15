# Test-only native compositor check. Never runs in normal gameplay.
extends RefCounted
static func run(main: Control) -> void:
 var tree := main.get_tree()
 if OS.get_name() != 'Windows':
  print('Native DWM transparency verification requires Windows.')
  tree.quit(0)
  return
 if RenderingServer.get_current_rendering_driver_name() != 'opengl3_angle':
  push_error('Windows transparency validation must use ANGLE; fallback is not accepted.')
  tree.quit(1)
  return
 var root := main.get_window()
 var layouts = main.layouts
 layouts.set_process(false)
 var backing := Window.new()
 backing.visible = false
 backing.force_native = true
 backing.transient = false
 backing.borderless = true
 backing.size = Vector2i(500,360)
 backing.position = DisplayServer.screen_get_usable_rect().position+Vector2i(50,50)
 var fill := ColorRect.new()
 fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 backing.add_child(fill)
 main.add_child(backing)
 backing.show()
 var output := OS.get_executable_path().get_base_dir().path_join('transparency-qa') if not OS.has_feature('editor') else 'res://docs/qa/layouts'
 DirAccess.make_dir_recursive_absolute(output)
 for mode in ['scene','mini','full','scene','mini']:
  layouts.apply(mode,false)
  layouts.toolbar.hide()
  root.borderless = true # Probe client pixels without native title-bar offsets.
  root.always_on_top = true
  root.position = backing.position+Vector2i(20,20)
  for color in [Color('e56e93'),Color('6ecfa5')]:
   fill.color = color
   for i in 4:
    await tree.process_frame
   await tree.create_timer(.3).timeout
   RenderingServer.force_draw()
   var screen := DisplayServer.screen_get_image(root.current_screen)
   if screen == null or screen.is_empty():
    push_error('Cannot read native desktop compositor output.')
    tree.quit(1)
    return
   # Probe the empty gutter below the custom titlebar, above LayoutMargin
   # content. (20,20) is now inside the app icon, not the opaque background.
   var inset := Vector2i(20,layouts.frame.HEIGHT+12) if mode == 'full' else Vector2i(2,2)
   var sample := root.position+inset-DisplayServer.screen_get_position(root.current_screen)
   var actual := screen.get_pixelv(sample)
   var expected: Color = layouts.background.color if mode == 'full' else color
   if maxf(absf(actual.r-expected.r),maxf(absf(actual.g-expected.g),absf(actual.b-expected.b))) > .12:
    push_error('Native desktop transparency failed: %s expected=%s actual=%s driver=%s' % [mode,expected,actual,RenderingServer.get_current_rendering_driver_name()])
    screen.save_png(output.path_join(mode+'-failed-desktop.png'))
    tree.quit(1)
    return
   print('Native composite matched %s backing=%s screen=%s' % [mode,color.to_html(false),actual])
   screen.save_png(output.path_join(mode+'-'+color.to_html(false)+'-desktop.png'))
 backing.queue_free()
 print('Windows native desktop composite passed: both floating modes expose changing backing colors; full remains opaque. Driver='+RenderingServer.get_current_rendering_driver_name())
 tree.quit(0)
