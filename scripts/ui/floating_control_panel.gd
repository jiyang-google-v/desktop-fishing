extends Window
var main
var layouts
var duration: SpinBox
var presets: Array[Button] = []
var pool: Label
var status: Label
var message: Label
var saved: Label
var sound: Button
var pause: Button
var skip: Button
var pending: Button
var pin: CheckButton
func _ready() -> void:
 visible = false
 force_native = true
 transient = true
 borderless = true
 transparent = true
 transparent_bg = true
 unresizable = true
 size = Vector2i(380,570)
 theme = main.theme
 var panel := PanelContainer.new()
 panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var skin = main.style(Color('fffbee'),20)
 skin.border_color = Color('9dc9d9')
 skin.set_border_width_all(2)
 panel.add_theme_stylebox_override('panel',skin)
 add_child(panel)
 var outer := VBoxContainer.new()
 outer.add_theme_constant_override('separation',10)
 panel.add_child(outer)
 var header := HBoxContainer.new()
 outer.add_child(header)
 var title: Label = main.label('专注设置',20)
 title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 title.mouse_filter = Control.MOUSE_FILTER_STOP
 title.mouse_default_cursor_shape = Control.CURSOR_MOVE
 title.gui_input.connect(func(e):
  if e is InputEventMouseButton and e.pressed and e.button_index==MOUSE_BUTTON_LEFT:
   start_drag())
 header.add_child(title)
 main.button('关闭',header,hide)
 var scroll := ScrollContainer.new()
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 outer.add_child(scroll)
 var body := VBoxContainer.new()
 body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 body.add_theme_constant_override('separation',10)
 scroll.add_child(body)
 status = main.paragraph('',body,13)
 message = main.paragraph('',body,12)
 message.add_theme_color_override('font_color',Color('a16b5c'))
 main.paragraph('专注时长 · 15–120 分钟',body,12)
 duration = SpinBox.new()
 duration.min_value = 15
 duration.max_value = 120
 duration.suffix = '分钟'
 duration.custom_minimum_size.y = 40
 body.add_child(duration)
 duration.value_changed.connect(func(value): main.handle(main.get_node('/root/Game').set_duration(int(value))); sync())
 var row := HBoxContainer.new()
 body.add_child(row)
 for minutes in [25,45,60]:
  var b: Button = main.button('%d 分钟' % minutes,row,func(): duration.value=minutes)
  b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  presets.append(b)
 pool = main.paragraph('',body,12)
 var actions := HBoxContainer.new()
 body.add_child(actions)
 pause = main.button('暂停',actions,func(): main.handle(main.get_node('/root/Game').toggle_pause()); sync())
 sound = main.button('声音',actions,func():
  var game = main.get_node('/root/Game')
  main.handle(game.set_sound_enabled(not game.state.sound_enabled))
  sync())
 pause.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 sound.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 skip = main.button('跳过当前动画',body,func(): main.ocean.skip(); sync())
 pending = main.button('查看并安置本次鱼获',body,func(): hide(); layouts.sync_catch(true))
 var collections := HBoxContainer.new()
 body.add_child(collections)
 main.button('鱼类图鉴',collections,func(): hide(); layouts.open_collection('book'))
 main.button('精选鱼缸',collections,func(): hide(); layouts.open_collection('tank'))
 pin = CheckButton.new()
 pin.text = '始终置顶'
 body.add_child(pin)
 pin.toggled.connect(func(value):
  layouts.pinned=value
  main.get_window().always_on_top=value
  layouts.save_settings())
 var maintenance := HBoxContainer.new()
 body.add_child(maintenance)
 main.button('检测与诊断',maintenance,main.show_diagnostics)
 main.button('保存退出',maintenance,func(): main.get_node('/root/Game').request_exit())
 saved = main.paragraph('',body,11)
 main.paragraph('前台、图鉴与无输入继续计时。锁屏或休眠后需手动继续；退出期间不累计。',body,11)
 close_requested.connect(hide)
 window_input.connect(func(e):
  if e is InputEventKey and e.pressed and e.keycode==KEY_ESCAPE:
   hide())
func open() -> void:
 var area := DisplayServer.screen_get_usable_rect()
 size = Vector2i(mini(380,area.size.x-24),mini(570,area.size.y-24))
 sync()
 popup_centered()
func _process(_delta: float) -> void:
 if visible:
  sync()
func sync() -> void:
 if duration == null:
  return
 var game = main.get_node('/root/Game')
 var state: Dictionary = game.state
 if not duration.get_line_edit().has_focus():
  duration.set_value_no_signal(state.duration_minutes)
 duration.editable = not game.blocked and not state.cast and state.pending_catch.is_empty()
 for b in presets:
  b.disabled = not duration.editable
 pool.text = game.model.group_label(state.duration_minutes)+'\n'+'、'.join(game.model.fish_pool(state.duration_minutes).map(func(f): return f.name))
 status.text = main.status_title.text+'\n'+main.status_text.text
 message.text = game.warning if not game.warning.is_empty() else main.action_error
 message.visible = not message.text.is_empty()
 saved.text = '最近保存：'+game.last_saved+(' · 保存失败' if game.save_failed else '')
 sound.text = '声音：开启' if state.sound_enabled else '声音：关闭'
 sound.disabled = game.blocked
 pause.text = '继续专注' if state.paused else '暂停专注'
 pause.disabled = game.blocked or not state.cast or game.model.completed(state)
 skip.visible = main.ocean.is_busy()
 pending.visible = not state.pending_catch.is_empty()
 pin.set_pressed_no_signal(layouts.pinned)
