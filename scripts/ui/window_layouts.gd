extends Control
const WindowFrame = preload('res://scripts/ui/window_frame.gd')
const TimerCard = preload('res://scripts/ui/pomodoro_card.gd')
const CatchPopup = preload('res://scripts/ui/floating_catch_popup.gd')
const Floating = preload('res://scripts/ui/floating_art_view.gd')
const SIZES := {'full':Vector2i(1100,796),'scene':Vector2i(420,280),'mini':Vector2i(180,176)}
var mode := 'full'
var main
var frame
var view
var timer_card
var background: ColorRect
var toolbar: VBoxContainer
var tools: Window
var mode_grid: GridContainer
var action_grid: GridContainer
var mode_buttons := {}
var action_buttons := {}
var hover_grace := 0.0
var opacity_row: HBoxContainer
var opacity_slider: HSlider
var opacity_label: Label
var opacity_open := false
var switching := false
var catch_popup
var dismissed_catch := ""
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
 timer_card = TimerCard.new()
 add_child(timer_card)
 timer_card.pause_requested.connect(func(): main.handle(main.get_node('/root/Game').toggle_pause()))
 catch_popup = CatchPopup.new()
 catch_popup.main = main
 catch_popup.theme = main.theme
 add_child(catch_popup)
 catch_popup.dismissed.connect(func(): dismissed_catch = str(main.get_node('/root/Game').state.pending_catch.get('catch_id','')))
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
 migrate_frame_settings()
 pinned = bool(settings.get_value('window','pinned',false))
 frame = WindowFrame.new()
 frame.main = main
 add_child(frame)
 get_window().size_changed.connect(on_window_resized)
 apply(str(settings.get_value('window','mode','full')),false)
func migrate_frame_settings() -> void:
 if int(settings.get_value('window','frame_version',0)) >= 1:
  return
 if settings.has_section_key('full','size'):
  var previous: Vector2i = settings.get_value('full','size',Vector2i(1100,760))
  previous.y += WindowFrame.HEIGHT
  settings.set_value('full','size',previous)
 settings.set_value('window','frame_version',1)
func build_tools() -> void:
 # Native Windows viewport/input ownership is recreated AFTER the parent changes.
 # Reusing a differently sized native child can retain stale mouse/focus state.
 if is_instance_valid(tools):
  tools.hide()
  tools.queue_free()
 mode_buttons.clear()
 action_buttons.clear()
 tools = Window.new()
 tools.visible = false
 tools.force_native = true
 tools.borderless = true
 tools.unresizable = true
 tools.transparent_bg = true
 tools.transparent = true
 tools.unfocusable = false
 tools.transient = true
 tools.theme = main.theme
 add_child(tools)
 var panel := PanelContainer.new()
 panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var skin: StyleBoxFlat = main.style(Color('fffbee'),12)
 skin.set_content_margin_all(8)
 panel.add_theme_stylebox_override('panel',skin)
 tools.add_child(panel)
 toolbar = VBoxContainer.new()
 toolbar.add_theme_constant_override('separation',6)
 panel.add_child(toolbar)
 mode_grid = GridContainer.new()
 mode_grid.columns = 1 if mode == 'scene' else 3
 toolbar.add_child(mode_grid)
 for entry in [['完整','full'],['悬浮','scene'],['极简','mini']]:
  var b := tool_button(entry[0],entry[1],mode_grid)
  b.pressed.connect(request_mode.bind(entry[1]))
  mode_buttons[entry[1]] = b
 action_grid = GridContainer.new()
 action_grid.columns = 1 if mode == 'scene' else 3
 toolbar.add_child(action_grid)
 for entry in [['放竿','cast'],['起竿','reel'],['图鉴','book'],['鱼缸','tank'],['透明度','opacity']]:
  var b := tool_button(entry[0],entry[1],action_grid)
  b.pressed.connect(request_action.bind(entry[1]))
  action_buttons[entry[1]] = b
 opacity_row = HBoxContainer.new()
 opacity_row.visible = opacity_open
 toolbar.add_child(opacity_row)
 opacity_slider = HSlider.new()
 opacity_slider.min_value = 30
 opacity_slider.max_value = 100
 opacity_slider.step = 5
 opacity_slider.value = opacity_percent()
 opacity_slider.custom_minimum_size = Vector2(54,28)
 opacity_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 opacity_slider.tooltip_text = '当前浮窗不透明度：30%–100%'
 opacity_slider.value_changed.connect(set_opacity_percent)
 opacity_row.add_child(opacity_slider)
 opacity_label = Label.new()
 opacity_label.add_theme_font_size_override('font_size',11)
 opacity_row.add_child(opacity_label)
 fit_tools()
func tool_button(text: String, icon_id: String, parent: Control) -> Button:
 var b := Button.new()
 b.text = text
 b.icon = load('res://assets/production/ui/'+icon_id+'.svg')
 b.expand_icon = true
 b.add_theme_constant_override('icon_max_width',18)
 b.add_theme_font_size_override('font_size',12)
 b.custom_minimum_size.y = 38
 b.add_theme_color_override('font_color',Color('2086b0'))
 for entry in [['normal','fffef5'],['hover','dcf8ff'],['pressed','bce9f6'],['disabled','e5f0ef']]:
  var skin: StyleBoxFlat = main.style(Color(entry[1]),8)
  skin.border_color = Color('83bed6')
  skin.set_border_width_all(1)
  skin.content_margin_left = 4
  skin.content_margin_right = 4
  skin.content_margin_top = 4
  skin.content_margin_bottom = 4
  b.add_theme_stylebox_override(entry[0],skin)
 b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 b.focus_mode = Control.FOCUS_NONE
 parent.add_child(b)
 return b
func fit_tools() -> void:
 var dimensions := Vector2i(132,364) if mode == 'scene' else Vector2i(320,160)
 if opacity_open:
  dimensions.y += 34
 tools.min_size = Vector2i.ZERO
 tools.max_size = Vector2i.ZERO
 tools.size = dimensions
 tools.min_size = dimensions
 tools.max_size = dimensions
 tools.content_scale_size = dimensions
 if tools.visible:
  tools.position = clamp_position(tools.position,dimensions)
func opacity_percent() -> int:
 return clampi(int(settings.get_value(mode,'opacity',100)),30,100)
func set_opacity_percent(value: float) -> void:
 if mode == 'full':
  return
 settings.set_value(mode,'opacity',clampi(roundi(value),30,100))
 apply_opacity()
 save_settings()
func apply_opacity() -> void:
 var alpha: float = opacity_percent()/100.0
 view.modulate.a = alpha
 timer_card.modulate.a = alpha
 if is_instance_valid(catch_popup):
  catch_popup.panel.modulate.a = alpha
 if is_instance_valid(opacity_label):
  opacity_label.text = '%d%%' % opacity_percent()
  opacity_slider.set_value_no_signal(opacity_percent())
func sync_catch(force: bool = false) -> void:
 var game = main.get_node('/root/Game')
 var id: String = str(game.state.pending_catch.get('catch_id',''))
 if id.is_empty():
  dismissed_catch = ''
  catch_popup.hide()
  return
 if mode == 'full' or main.ocean.is_busy() or main.collection.visible or main.confirmation.visible:
  catch_popup.hide()
  return
 if not force and dismissed_catch == id:
  return
 if force:
  dismissed_catch = ''
 catch_popup.present(game)
 # Transient windows inherit their owner's stacking; a separate on-top flag conflicts.
 var offset := Vector2i(-catch_popup.size.x-8,0) if mode == 'scene' else Vector2i(get_window().size.x-catch_popup.size.x,-catch_popup.size.y-8)
 catch_popup.position = clamp_position(get_window().position+offset,catch_popup.size)
 if not catch_popup.visible:
  tools.hide()
  catch_popup.show()
func clamp_position(value: Vector2i, dimensions: Vector2i) -> Vector2i:
 var area := DisplayServer.screen_get_usable_rect()
 return Vector2i(clampi(value.x,area.position.x,maxi(area.position.x,area.end.x-dimensions.x)),clampi(value.y,area.position.y,maxi(area.position.y,area.end.y-dimensions.y)))
func on_window_resized() -> void:
 if mode == 'full':
  get_window().content_scale_size = get_window().size
func remember() -> void:
 if mode == 'full':
  if get_window().mode == Window.MODE_MINIMIZED:
   return
  var maximized: bool = frame.is_maximized()
  settings.set_value('full','maximized',maximized)
  if maximized:
   return
  settings.set_value(mode,'size',get_window().size)
 settings.set_value(mode,'position',get_window().position)
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
 var keep_tools: bool = is_instance_valid(tools) and tools.visible and mode != 'full' and next != 'full'
 var tool_position: Vector2i = tools.position if is_instance_valid(tools) else Vector2i.ZERO
 if is_instance_valid(tools):
  tools.hide()
 catch_popup.hide()
 switching = false
 drag = false
 hover_grace = 1.0 if keep_tools else 0.0
 mode = next
 opacity_open = false
 var window := get_window()
 var compact: bool = mode != 'full'
 frame.manual_maximized = false
 window.mode = Window.MODE_WINDOWED
 frame.visible = not compact
 frame.last_mode = -1
 main.get_node('LayoutMargin').visible = not compact
 view.visible = compact
 view.profile = mode if compact else 'scene'
 timer_card.visible = compact
 # Preserve the original 160x100 minimal rig below the shared timer.
 view.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
 view.position = Vector2(10,76) if mode == 'mini' else Vector2.ZERO
 view.size = Vector2(160,100) if mode == 'mini' else Vector2(SIZES[mode])
 timer_card.position = Vector2(6,4) if mode == 'mini' else Vector2(244,2)
 timer_card.size = Vector2(168,70) if mode == 'mini' else Vector2(164,68)
 # Clear old size limits before applying new ones, including mini -> full.
 window.max_size = Vector2i.ZERO
 window.min_size = Vector2i.ZERO
 window.min_size = Vector2i(940,736) if not compact else SIZES[mode]
 window.max_size = Vector2i.ZERO if not compact else SIZES[mode]
 window.borderless = true
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
 build_tools()
 toolbar.visible = true
 apply_opacity()
 sync_tools()
 if keep_tools:
  tools.position = clamp_position(tool_position,tools.size)
  tools.show()
 view.queue_redraw()
 if not compact and bool(settings.get_value('full','maximized',false)):
  frame.maximize()
 if persist:
  save_settings()
func menu_action(id: int) -> void:
 if id < 3:
  apply(['full','scene','mini'][id])
 elif id == 3:
  if not main.get_node('/root/Game').state.pending_catch.is_empty():
   sync_catch(true)
  else:
   main.perform_fishing('reel' if main.get_node('/root/Game').state.cast else 'cast')
 elif id == 4:
  sync_catch(true)
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
 if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and timer_card.visible and timer_card.get_rect().has_point(event.position):
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
 sync_tools()
 sync_catch()
 view.night = main.ocean.night
 var action: String = main.ocean.motion.active
 view.action_progress = main.ocean.motion.progress
 view.caught_texture = main.Portrait.texture_for(str(main.get_node('/root/Game').state.pending_catch.get('species_id',''))) if not main.get_node('/root/Game').state.pending_catch.is_empty() else null
 if action in ['cast','reel']:
  view.action = action
  view.age = main.ocean.motion.elapsed
 else:
  view.action = 'happy' if not main.get_node('/root/Game').state.pending_catch.is_empty() else 'idle'

 view.line_cast = main.get_node('/root/Game').state.cast
 if main.collection.visible or main.confirmation.visible or catch_popup.visible:
  tools.hide()
  return
 if should_show_tools(DisplayServer.mouse_get_position()) and not drag:
  hover_grace = .4
  show_tools()
 else:
  hover_grace -= _delta
  if hover_grace <= 0:
   tools.hide()

func sync_tools() -> void:
 for key in mode_buttons:
  mode_buttons[key].disabled = key == mode
 var game = main.get_node('/root/Game')
 timer_card.sync(game,main.ocean.night)
 action_buttons.cast.disabled = switching or main.ocean.is_busy() or game.blocked or game.state.cast or not game.state.pending_catch.is_empty()
 action_buttons.cast.tooltip_text = '按当前设定的%d分钟开始番茄钟' % game.state.duration_minutes
 action_buttons.reel.text = '鱼获' if not game.state.pending_catch.is_empty() else ('起竿' if game.model.completed(game.state) else '提前起竿')
 action_buttons.reel.disabled = switching or main.ocean.is_busy() or game.blocked or (not game.state.cast and game.state.pending_catch.is_empty())
 action_buttons.reel.tooltip_text = '提前起竿会失败，需确认。' if game.state.cast and not game.model.completed(game.state) else '查看并安置本次鱼获。'
 action_buttons.opacity.tooltip_text = '调节当前浮窗透明度 · 不透明度%d%%' % opacity_percent()
func should_show_tools(screen_point: Vector2i) -> bool:
 if mode == 'full':
  return false
 if tools.visible and Rect2i(tools.position,tools.size).has_point(screen_point):
  return true
 var local := Vector2(screen_point-get_window().position)
 if timer_card.visible and timer_card.get_rect().has_point(local):
  return false
 if mode == 'scene':
  return Rect2(Vector2.ZERO,size).has_point(local)
 local -= view.position
 var rig: Dictionary = view.rig_geometry()
 var start: Vector2 = rig.tip
 var end: Vector2 = rig.hand
 return local.distance_to(Geometry2D.get_closest_point_to_segment(local,start,end)) <= 24.0
func show_tools() -> void:
 sync_tools()
 # Native toolbar stays above its owner through transient ownership.
 if not tools.visible:
  var offset := Vector2i(-tools.size.x-6,0) if mode == "scene" else Vector2i(get_window().size.x-tools.size.x,-tools.size.y-6)
  tools.position = clamp_position(get_window().position+offset,tools.size)
  tools.show()
func open_collection(kind: String) -> void:
 tools.hide()
 main.open_collection(kind)
func tool_action(kind: String) -> void:
 if kind in ['book','tank']:
  open_collection(kind)
 elif kind == 'opacity':
  opacity_open = not opacity_open
  opacity_row.visible = opacity_open
  fit_tools()
  hover_grace = 1.0
 elif kind == 'cast' and not action_buttons.cast.disabled:
  main.perform_fishing('cast')
 elif kind == 'reel':
  if not main.get_node('/root/Game').state.pending_catch.is_empty():
   sync_catch(true)
  elif not action_buttons.reel.disabled:
   main.perform_fishing('reel')
 sync_tools()

func request_mode(next: String) -> void:
 # Ignore duplicate native requests until the current release is completely handled.
 if switching:
  return
 switching = true
 apply.call_deferred(next)

func request_action(kind: String) -> void:
 # Hide/open native windows only after the mouse release has finished.
 tool_action.call_deferred(kind)
