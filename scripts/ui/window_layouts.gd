extends Control
const Floating = preload('res://scripts/ui/floating_art_view.gd')
const SIZES := {'full':Vector2i(1100,760),'scene':Vector2i(420,280),'mini':Vector2i(160,100)}
var mode := 'full'
var main
var view
var toolbar: HBoxContainer
var menu: PopupMenu
var settings := ConfigFile.new()
var drag := false
var drag_origin := Vector2i.ZERO
var drag_window := Vector2i.ZERO
var pinned := false
var test_mode := false
func _ready() -> void:
 main = get_parent()
 test_mode = '--tests' in OS.get_cmdline_user_args()
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 view = Floating.new()
 view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(view)
 toolbar = HBoxContainer.new()
 toolbar.position = Vector2(8,8)
 add_child(toolbar)
 for entry in [['完整','full'],['悬浮','scene'],['极简','mini']]:
  var b := Button.new()
  b.text = entry[0]
  b.pressed.connect(apply.bind(entry[1]))
  toolbar.add_child(b)
 menu = PopupMenu.new()
 add_child(menu)
 menu.add_item('完整窗口',0)
 menu.add_item('场景悬浮',1)
 menu.add_item('极简悬浮',2)
 menu.add_separator()
 menu.add_item('放钩 / 收杆',3)
 menu.add_item('安置鱼获',4)
 menu.add_check_item('始终置顶',5)
 menu.add_item('保存退出',6)
 menu.id_pressed.connect(menu_action)
 if not test_mode:
  settings.load('user://window-layouts.cfg')
 pinned = bool(settings.get_value('window','pinned',false))
 apply(str(settings.get_value('window','mode','full')),false)
func clamp_position(value: Vector2i, dimensions: Vector2i) -> Vector2i:
 var area := DisplayServer.screen_get_usable_rect()
 return Vector2i(clampi(value.x,area.position.x,maxi(area.position.x,area.end.x-dimensions.x)),clampi(value.y,area.position.y,maxi(area.position.y,area.end.y-dimensions.y)))
func remember() -> void:
 settings.set_value(mode,'position',get_window().position)
 if mode == 'full':
  settings.set_value(mode,'size',get_window().size)
func save_settings() -> void:
 if test_mode:
  return
 remember()
 settings.set_value('window','mode',mode)
 settings.set_value('window','pinned',pinned)
 if settings.save('user://window-layouts.cfg') != OK:
  push_warning('Window preference save failed; fishing save is unaffected.')
func apply(next: String, persist: bool = true) -> void:
 if not SIZES.has(next):
  return
 if persist:
  remember()
 mode = next
 var window := get_window()
 var compact: bool = mode != 'full'
 main.get_node('LayoutMargin').visible = not compact
 view.visible = compact
 view.profile = mode if compact else 'scene'
 window.min_size = Vector2i(940,700) if not compact else SIZES[mode]
 window.max_size = Vector2i.ZERO if not compact else SIZES[mode]
 window.borderless = compact
 window.unresizable = compact
 window.transparent = compact
 window.transparent_bg = compact
 window.always_on_top = pinned
 window.size = settings.get_value('full','size',SIZES.full) if not compact else SIZES[mode]
 window.content_scale_size = window.size
 var area := DisplayServer.screen_get_usable_rect()
 var fallback := area.end-window.size-Vector2i(16,16) if compact else area.position+(area.size-window.size)/2
 window.position = clamp_position(settings.get_value(mode,'position',fallback),window.size)
 toolbar.visible = false
 view.queue_redraw()
 if persist:
  save_settings()
func menu_action(id: int) -> void:
 if id < 3:
  apply(['full','scene','mini'][id])
 elif id == 3:
  if not main.get_node('/root/Game').state.pending_catch.is_empty():
   apply('full')
  else:
   main.perform_fishing('reel' if main.get_node('/root/Game').state.cast else 'cast')
 elif id == 4:
  apply('full')
 elif id == 5:
  pinned = not pinned
  get_window().always_on_top = pinned
  save_settings()
 elif id == 6:
  main.get_node('/root/Game').request_exit()
func _input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode == KEY_ESCAPE and mode != 'full':
   apply('full')
 if mode == 'full':
  return
 if event is InputEventMouseButton:
  if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
   menu.set_item_checked(menu.get_item_index(5),pinned)
   menu.position = DisplayServer.mouse_get_position()
   menu.popup()
  elif event.button_index == MOUSE_BUTTON_LEFT:
   drag = event.pressed
   if drag:
    drag_origin = DisplayServer.mouse_get_position()
    drag_window = get_window().position
   else:
    save_settings()
 if event is InputEventMouseMotion and drag:
  get_window().position = clamp_position(drag_window+DisplayServer.mouse_get_position()-drag_origin,get_window().size)
func _process(_delta: float) -> void:
 if mode == 'full':
  return
 toolbar.visible = mode == 'scene' and Rect2(Vector2.ZERO,size).has_point(get_local_mouse_position())
 view.night = main.ocean.night
 var action: String = main.ocean.motion.active
 if action in ['cast','reel']:
  view.action = action
  view.age = main.ocean.motion.elapsed
 else:
  view.action = 'happy' if not main.get_node('/root/Game').state.pending_catch.is_empty() else 'idle'
