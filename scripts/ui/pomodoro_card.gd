# A shared view over Game's existing clock; switching layouts never owns/reset time.
extends Control
signal pause_requested
const DIR := 'res://assets/production/ui/pomodoro/'
const SUN = preload(DIR+'sun.png')
const MOON = preload(DIR+'moon.png')
var design: Control
var day_icon: TextureRect
var time_label: Label
var status_label: Label
var pause_button: TextureButton
var progress: ProgressBar
var busy := false
func _ready() -> void:
 name = 'PomodoroCardA'
 mouse_filter = Control.MOUSE_FILTER_STOP
 design = Control.new()
 design.mouse_filter = Control.MOUSE_FILTER_IGNORE
 design.size = Vector2(184,76)
 add_child(design)
 var panel := TextureRect.new()
 panel.texture = load(DIR+'panel.png')
 panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 panel.stretch_mode = TextureRect.STRETCH_SCALE
 place(panel,Vector2.ZERO,Vector2(184,76))
 day_icon = TextureRect.new()
 day_icon.texture = SUN
 day_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 day_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 place(day_icon,Vector2(10,14),Vector2(34,34))
 time_label = Label.new()
 time_label.add_theme_font_size_override('font_size',24)
 time_label.add_theme_color_override('font_color',Color('39749f'))
 time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 place(time_label,Vector2(44,9),Vector2(98,30))
 status_label = Label.new()
 status_label.add_theme_font_size_override('font_size',11)
 status_label.add_theme_color_override('font_color',Color('527a96'))
 status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 place(status_label,Vector2(44,37),Vector2(98,17))
 progress = ProgressBar.new()
 progress.show_percentage = false
 progress.max_value = 1.0
 progress.step = .0001
 for entry in [['background','track'],['fill','fill']]:
  var style := StyleBoxTexture.new()
  style.texture = load(DIR+entry[1]+'.png')
  style.texture_margin_left = 9
  style.texture_margin_right = 9
  progress.add_theme_stylebox_override(entry[0],style)
 place(progress,Vector2(14,59),Vector2(156,7))
 pause_button = TextureButton.new()
 pause_button.ignore_texture_size = true
 pause_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
 pause_button.focus_mode = Control.FOCUS_ALL
 place(pause_button,Vector2(144,18),Vector2(30,30))
 pause_button.mouse_filter = Control.MOUSE_FILTER_STOP
 pause_button.pressed.connect(func(): pause_requested.emit())
 resized.connect(fit)
 fit()
func place(control: Control, at: Vector2, dimensions: Vector2) -> void:
 control.position = at
 control.size = dimensions
 control.mouse_filter = Control.MOUSE_FILTER_IGNORE
 design.add_child(control)
func fit() -> void:
 if design != null:
  design.scale = size/Vector2(184,76)
func sync(game: Node, night: bool) -> void:
 if design == null:
  return
 var state: Dictionary = game.state
 var remaining: int = int(ceil(game.remaining_seconds()))
 time_label.text = '%02d:%02d' % [remaining/60,remaining%60]
 var completed: bool = game.model.completed(state)
 status_label.text = '专注中'
 if not state.pending_catch.is_empty():
  status_label.text = '待安置'
 elif not state.cast:
  status_label.text = '待放竿'
 elif completed:
  status_label.text = '可以收竿了'
 elif state.paused or game.blocked:
  status_label.text = '已暂停'
 elif game.focus_status.get('transient',false):
  status_label.text = '检测中'
 status_label.add_theme_color_override('font_color',Color('267b83') if completed else Color('527a96'))
 status_label.add_theme_font_size_override('font_size',12 if completed else 11)
 day_icon.texture = MOON if night else SUN
 progress.value = clampf(state.focus_seconds/maxf(state.duration_minutes*60.0,1.0),0.0,1.0)
 var symbol := 'play' if state.paused or not state.cast else 'pause'
 pause_button.texture_normal = load(DIR+symbol+'-normal.png')
 pause_button.texture_hover = load(DIR+symbol+'-hover.png')
 pause_button.texture_pressed = load(DIR+symbol+'-pressed.png')
 pause_button.texture_disabled = load(DIR+symbol+'-disabled.png')
 pause_button.disabled = game.blocked or completed or not state.pending_catch.is_empty() or busy
 pause_button.tooltip_text = '放竿并开始专注' if not state.cast else ('继续专注' if state.paused else '暂停专注')
 if not state.pending_catch.is_empty():
  pause_button.tooltip_text = '请先安置本次鱼获，再开始下一次专注'
 elif completed:
  pause_button.tooltip_text = '专注已完成，请起竿揭晓鱼获'
 elif busy:
  pause_button.tooltip_text = '钓鱼动画播放中'
 tooltip_text = '点击时钟打开专注设置\n番茄钟 · %d 分钟 · %s 类鱼池 · %s' % [state.duration_minutes,game.model.group_for(state.duration_minutes),status_label.text]

 if state.paused:
  tooltip_text += '\n暂停原因：'+str({'manual':'手动暂停','locked':'系统锁屏','sleep':'休眠或计时中断','system':'系统检测重启','restart':'重新打开游戏','detection':'检测持续失联'}.get(state.pause_cause,state.pause_cause))
