extends Control
const Floating = preload('res://scripts/ui/floating_art_view.gd')
const SIZES := {'full':Vector2i(1100,760),'scene':Vector2i(420,280),'mini':Vector2i(160,100)}
var mode := 'full'
var main
var view
var background: ColorRect
var toolbar: VBoxContainer
var tools: Window
var mode_buttons := {}
var action_buttons := {}
var hover_grace := 0.0
var timer_label: Label
var pause_control: Button
var menu: PopupMenu
var settings := ConfigFile.new()
var drag := false
var drag_origin := Vector2i.ZERO
var drag_window := Vector2i.ZERO
var pinned := false
var test_mode := false
func _ready() -> void:
 main = get_parent()
 # Keep the native alpha surface alive in every layout. Full mode paints its own opaque backdrop.
 background = ColorRect.new()
 background.name = 'FullWindowBackground'
 background.color = Color(0.929,0.949,0.929,1)
 background.mouse_filter = Control.MOUSE_FILTER_IGNORE
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 main.add_child(background)
 main.move_child(background,0)
 test_mode = '--tests' in OS.get_cmdline_user_args()
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 view = Floating.new()
 view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(view)
 tools = Window.new()
 tools.visible = false
 tools.force_native = true
 tools.borderless = true
 tools.unresizable = true
 tools.transparent_bg = true
 tools.transparent = true
 # Interactive native windows must accept focus for Windows to deliver button clicks.
 tools.unfocusable = false
 tools.transient = true
 tools.size = Vector2i(320,160)
 tools.content_scale_size = tools.size
 tools.theme = main.theme
 add_child(tools)
 var panel := PanelContainer.new()
 panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var style := StyleBoxFlat.new()
 style.bg_color = Color('fffbee')
 style.border_color = Color('a9c8d4')
 style.set_border_width_all(1)
 style.set_corner_radius_all(12)
 style.content_margin_left = 8
 style.content_margin_right = 8
 style.content_margin_top = 8
 style.content_margin_bottom = 8
 panel.add_theme_stylebox_override('panel',style)
 tools.add_child(panel)
 toolbar = VBoxContainer.new()
 toolbar.add_theme_constant_override('separation',6)
 panel.add_child(toolbar)
 var timer_row := HBoxContainer.new()
 toolbar.add_child(timer_row)
 timer_label = Label.new()
 timer_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 timer_row.add_child(timer_label)
 pause_control = Button.new()
 pause_control.text = '暂停'
 pause_control.pressed.connect(func(): main.handle(main.get_node('/root/Game').toggle_pause()))
 timer_row.add_child(pause_control)
 var modes := HBoxContainer.new()
 toolbar.add_child(modes)
 for entry in [['完整','full'],['悬浮','scene'],['极简','mini']]:
  var b := Button.new()
  b.text = entry[0]
  b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  b.focus_mode = Control.FOCUS_NONE
  b.pressed.connect(request_mode.bind(entry[1]))
  modes.add_child(b)
  mode_buttons[entry[1]] = b
 var actions := HBoxContainer.new()
 toolbar.add_child(actions)
 for entry in [['收杆','reel'],['图鉴','book'],['鱼缸','tank']]:
  var b := Button.new()
  b.text = entry[0]
  b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  b.pressed.connect(request_action.bind(entry[1]))
  actions.add_child(b)
  action_buttons[entry[1]] = b
 menu = PopupMenu.new()
 menu.force_native = true
 add_child(menu)
 menu.add_item('完整窗口',0)
 menu.add_item('场景悬浮',1)
 menu.add_item('极简悬浮',2)
 menu.add_separator()
 menu.add_item('放钩 / 收杆',3)
 menu.add_item('安置鱼获',4)
 menu.add_check_item('始终置顶',5)
 menu.add_item('保存退出',6)
 menu.add_item('查看图鉴',7)
 menu.add_item('查看鱼缸',8)
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
 var keep_tools: bool = tools.visible and mode != "full" and next != "full"
 if not keep_tools:
  tools.hide()
 drag = false
 hover_grace = .4 if keep_tools else 0.0
 mode = next
 var window := get_window()
 var compact: bool = mode != 'full'
 main.get_node('LayoutMargin').visible = not compact
 view.visible = compact
 view.profile = mode if compact else 'scene'
 # Clear old size limits before applying new ones, including mini -> full.
 window.max_size = Vector2i.ZERO
 window.min_size = Vector2i.ZERO
 window.min_size = Vector2i(940,700) if not compact else SIZES[mode]
 window.max_size = Vector2i.ZERO if not compact else SIZES[mode]
 window.borderless = compact
 window.unresizable = compact
 background.visible = not compact
 window.transparent_bg = true
 window.transparent = true
 window.always_on_top = pinned
 window.size = settings.get_value('full','size',SIZES.full) if not compact else SIZES[mode]
 window.content_scale_size = window.size
 var area := DisplayServer.screen_get_usable_rect()
 var fallback := area.end-window.size-Vector2i(16,16) if compact else area.position+(area.size-window.size)/2
 window.position = clamp_position(settings.get_value(mode,'position',fallback),window.size)
 toolbar.visible = true
 sync_tools()
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
 elif id == 7:
  open_collection('book')
 elif id == 8:
  open_collection('tank')
 elif id == 6:
  main.get_node('/root/Game').request_exit()
func _input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode == KEY_ESCAPE and mode != 'full':
   apply('full')
 if mode == 'full':
  return
 if tools.visible and Rect2i(tools.position,tools.size).has_point(DisplayServer.mouse_get_position()):
  drag = false
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
 if main.collection.visible or main.confirmation.visible:
  tools.hide()
  return
 if should_show_tools(DisplayServer.mouse_get_position()) and not drag:
  hover_grace = .4
  show_tools()
 else:
  hover_grace -= _delta
  if hover_grace <= 0:
   tools.hide()
 sync_tools()
 view.night = main.ocean.night
 var action: String = main.ocean.motion.active
 if action in ['cast','reel']:
  view.action = action
  view.age = main.ocean.motion.elapsed
 else:
  view.action = 'happy' if not main.get_node('/root/Game').state.pending_catch.is_empty() else 'idle'

func sync_tools() -> void:
 for key in mode_buttons:
  mode_buttons[key].disabled = key == mode
 var game = main.get_node('/root/Game')
 var remaining: int = int(ceil(game.remaining_seconds()))
 timer_label.text = '%s · %02d:%02d' % [game.model.group_for(game.state.duration_minutes),remaining/60,remaining%60]
 if game.model.completed(game.state):
  timer_label.text = '专注完成 · 可以起竿'
 elif game.state.paused:
  timer_label.text += ' · 已暂停'
 pause_control.text = '继续' if game.state.paused else '暂停'
 pause_control.disabled = game.blocked or not game.state.cast or game.model.completed(game.state)
 action_buttons.reel.text = '安置鱼获' if not game.state.pending_catch.is_empty() else ('起竿' if game.model.completed(game.state) else '提前起竿')
 action_buttons.reel.disabled = main.ocean.is_busy() or game.blocked or (not game.state.cast and game.state.pending_catch.is_empty())
 action_buttons.reel.tooltip_text = '请先在完整窗口放钩。' if action_buttons.reel.disabled else ('提前起竿会失败，需确认。' if game.state.cast and not game.model.completed(game.state) else '完成后起竿揭晓鱼获。')
func should_show_tools(screen_point: Vector2i) -> bool:
 if mode == 'full':
  return false
 if tools.visible and Rect2i(tools.position,tools.size).has_point(screen_point):
  return true
 var local := Vector2(screen_point-get_window().position)
 if mode == 'scene':
  return Rect2(Vector2.ZERO,size).has_point(local)
 var rig: Dictionary = view.rig_geometry()
 var start: Vector2 = rig.tip
 var end: Vector2 = rig.hand
 return local.distance_to(Geometry2D.get_closest_point_to_segment(local,start,end)) <= 24.0
func show_tools() -> void:
 sync_tools()
 tools.always_on_top = pinned
 if not tools.visible:
  tools.position = clamp_position(get_window().position+Vector2i(get_window().size.x-tools.size.x,-tools.size.y-6),tools.size)
  tools.show()
func open_collection(kind: String) -> void:
 tools.hide()
 main.open_collection(kind)
func tool_action(kind: String) -> void:
 if kind in ['book','tank']:
  open_collection(kind)
 elif not main.get_node('/root/Game').state.pending_catch.is_empty():
  apply('full')
 elif not action_buttons.reel.disabled:
  main.perform_fishing('reel')

func request_mode(next: String) -> void:
 # Finish the native button event before changing its owner window.
 apply.call_deferred(next)

func request_action(kind: String) -> void:
 # Hide/open native windows only after the mouse release has finished.
 tool_action.call_deferred(kind)
