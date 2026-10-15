extends Control
const HEIGHT := 36
const ICON = preload('res://assets/production/ui/app-icon.svg')
var main
var bar: PanelContainer
var drag_area: HBoxContainer
var buttons := {}
var handles: Array[Control] = []
var last_mode := -1
func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 bar = PanelContainer.new()
 bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
 bar.offset_bottom = HEIGHT
 var skin := StyleBoxFlat.new()
 skin.bg_color = Color('fffbee')
 skin.border_color = Color('bfd5df')
 skin.border_width_bottom = 1
 skin.content_margin_left = 12
 skin.content_margin_right = 6
 skin.content_margin_top = 2
 skin.content_margin_bottom = 2
 bar.add_theme_stylebox_override('panel',skin)
 add_child(bar)
 var row := HBoxContainer.new()
 row.add_theme_constant_override('separation',4)
 bar.add_child(row)
 drag_area = HBoxContainer.new()
 drag_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 drag_area.mouse_filter = Control.MOUSE_FILTER_STOP
 drag_area.mouse_default_cursor_shape = Control.CURSOR_MOVE
 drag_area.add_theme_constant_override('separation',8)
 drag_area.gui_input.connect(on_drag_input)
 row.add_child(drag_area)
 var icon := TextureRect.new()
 icon.texture = ICON
 icon.custom_minimum_size = Vector2(24,24)
 icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
 drag_area.add_child(icon)
 var caption: Label = main.label('桌面钓鱼',14)
 caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
 drag_area.add_child(caption)
 for kind in ['minimize','maximize','close']:
  var b := Button.new()
  b.icon = load('res://assets/production/ui/window-'+kind+'.svg')
  b.expand_icon = true
  b.add_theme_constant_override('icon_max_width',16)
  b.custom_minimum_size = Vector2(34,30)
  b.focus_mode = Control.FOCUS_NONE
  for state in ['normal','hover','pressed','focus']:
   var button_skin := StyleBoxFlat.new()
   button_skin.set_corner_radius_all(8)
   button_skin.set_content_margin_all(6)
   button_skin.bg_color = Color(0,0,0,0) if state == 'normal' else Color('dfedf3')
   if kind == 'close' and state != 'normal':
    button_skin.bg_color = Color('f4ded6')
   b.add_theme_stylebox_override(state,button_skin)
  row.add_child(b)
  buttons[kind] = b
 buttons.minimize.tooltip_text = '最小化'
 buttons.minimize.pressed.connect(minimize)
 buttons.maximize.tooltip_text = '最大化'
 buttons.maximize.pressed.connect(toggle_maximize)
 buttons.close.tooltip_text = '保存并关闭'
 buttons.close.pressed.connect(request_close)
 # Six-pixel native resize targets preserve resizing without an OS title bar.
 for spec in [[0,0,0,1,0,0,6,0,DisplayServer.WINDOW_EDGE_LEFT,Control.CURSOR_HSIZE], [1,0,1,1,-6,0,0,0,DisplayServer.WINDOW_EDGE_RIGHT,Control.CURSOR_HSIZE], [0,0,1,0,0,0,0,5,DisplayServer.WINDOW_EDGE_TOP,Control.CURSOR_VSIZE], [0,1,1,1,0,-6,0,0,DisplayServer.WINDOW_EDGE_BOTTOM,Control.CURSOR_VSIZE], [0,0,0,0,0,0,10,10,DisplayServer.WINDOW_EDGE_TOP_LEFT,Control.CURSOR_FDIAGSIZE], [1,0,1,0,-10,0,0,10,DisplayServer.WINDOW_EDGE_TOP_RIGHT,Control.CURSOR_BDIAGSIZE], [0,1,0,1,0,-10,10,0,DisplayServer.WINDOW_EDGE_BOTTOM_LEFT,Control.CURSOR_BDIAGSIZE], [1,1,1,1,-10,-10,0,0,DisplayServer.WINDOW_EDGE_BOTTOM_RIGHT,Control.CURSOR_FDIAGSIZE]]:
  var handle := Control.new()
  handle.anchor_left = spec[0]
  handle.anchor_top = spec[1]
  handle.anchor_right = spec[2]
  handle.anchor_bottom = spec[3]
  handle.offset_left = spec[4]
  handle.offset_top = spec[5]
  handle.offset_right = spec[6]
  handle.offset_bottom = spec[7]
  handle.mouse_default_cursor_shape = spec[9]
  handle.mouse_filter = Control.MOUSE_FILTER_STOP
  handle.gui_input.connect(on_resize_input.bind(spec[8]))
  add_child(handle)
  handles.append(handle)
func _process(_delta: float) -> void:
 if not visible:
  return
 var mode: int = get_window().mode
 if mode == last_mode:
  return
 last_mode = mode
 var maximized: bool = is_maximized()
 buttons.maximize.icon = load('res://assets/production/ui/window-restore.svg' if maximized else 'res://assets/production/ui/window-maximize.svg')
 buttons.maximize.tooltip_text = '还原窗口' if maximized else '最大化'
 for handle in handles:
  handle.visible = mode == Window.MODE_WINDOWED
func on_drag_input(event: InputEvent) -> void:
 if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
  if event.double_click:
   toggle_maximize()
  else:
   get_window().start_drag()
  drag_area.accept_event()
func on_resize_input(event: InputEvent, edge: int) -> void:
 if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and get_window().mode == Window.MODE_WINDOWED:
  get_window().start_resize(edge)
func is_maximized() -> bool:
 return get_window().mode == Window.MODE_MAXIMIZED
func maximize() -> void:
 var window := get_window()
 if OS.get_name() == 'Windows' and window.borderless:
  # Establish Win32's native zoomed state before removing decorations.
  # Godot's direct borderless maximize path uses MoveWindow and can lose
  # its maximized flag during the two-pixel screen-edge compensation.
  window.borderless = false
  window.mode = Window.MODE_MAXIMIZED
  window.borderless = true
 else:
  window.mode = Window.MODE_MAXIMIZED
func toggle_maximize() -> void:
 if is_maximized():
  get_window().mode = Window.MODE_WINDOWED
  main.layouts.settings.set_value('full','maximized',false)
 else:
  main.layouts.remember()
  maximize()
 main.layouts.save_settings()
func minimize() -> void:
 main.layouts.remember()
 main.layouts.save_settings()
 get_window().mode = Window.MODE_MINIMIZED
func request_close() -> void:
 main.layouts.save_settings()
 main.get_node('/root/Game').request_exit()
