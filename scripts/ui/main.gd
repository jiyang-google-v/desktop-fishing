extends Control

const SceneAudio = preload("res://scripts/services/scene_audio.gd")
const Portrait = preload("res://scripts/ui/fish_portrait.gd")
const Aquarium = preload("res://scripts/ui/aquarium_view.gd")
const Ocean = preload("res://scripts/ui/ocean_view.gd")
const RARITY := {"common":"常见","uncommon":"少见","rare":"稀有","legendary":"传说"}
const STATUS := {
 "ready":["准备专注","设定番茄钟时长，再放竿开始。完成后才能成功起竿。"],
 "working":["专注进行中","专注由你定义。可随时暂停；提前起竿则本次失败。"],
 "paused":["番茄钟已暂停","剩余时间已保留，准备好后点击继续。"],
 "completed":["专注完成！","可以起竿，揭晓本次时间档的鱼获。"],
 "failed":["本次挑战失败","提前起竿，没有鱼获。可以重新设定并开始。"],
 "pending":["本次鱼获待安置","收进鱼缸或放生后，即可再次放竿。"],
 "blocked":["存档需要处理","为保护已有数据，已暂停游戏操作。"]
}
var layouts
var ocean
var scene_audio
var sound_button: Button
var skip_button: Button
var status_title: Label
var status_text: Label
var depth_text: Label
var time_text: Label
var scene_text: Label
var focus_card: PanelContainer
var progress: ProgressBar
var cast_button: Button
var reel_button: Button
var fishing_actions: HBoxContainer
var book_button: Button
var tank_button: Button
var catch_box: VBoxContainer
var notice: Label
var feedback_toast: Label
var feedback_tween: Tween
var reveal_tween: Tween
var tank_tween: Tween
var timer_setup: VBoxContainer
var duration_input: SpinBox
var pause_button: Button
var pool_preview: Label
var book_filter: OptionButton
var book_group := "all"
var completion_notified := ""
var saved_label: Label
var diagnostic_dialog: AcceptDialog
var collection: Window
var collection_title: Label
var collection_description: Label
var collection_notice: Label
var collection_feedback: Label
var collection_close: Button
var action_error := ""
var aquarium_view
var collection_grid: GridContainer
var collection_progress: ProgressBar
var collection_tabs := {}
var confirmation: ConfirmationDialog
var confirm_action := Callable()
var panel_mode := "book"
var replacing := false
var catch_signature := ""
var panel_signature := ""

func _ready() -> void:
 get_tree().auto_accept_quit = false
 Engine.max_fps = 30
 OS.low_processor_usage_mode = true
 OS.low_processor_usage_mode_sleep_usec = 33000
 get_window().min_size = Vector2i(940,736)
 if "--tests" in OS.get_cmdline_user_args() and "--small" in OS.get_cmdline_user_args():
  get_window().content_scale_size = Vector2i(940,736)
  get_window().size = Vector2i(940,736)
 get_window().title = "桌面钓鱼"
 if DisplayServer.get_name() != "headless":
  DisplayServer.set_icon(load("res://assets/production/ui/app-icon.png").get_image())
 scene_audio = SceneAudio.new()
 add_child(scene_audio)
 theme = make_theme()
 build_ui()
 layouts = load("res://scripts/ui/window_layouts.gd").new()
 add_child(layouts)
 Game.changed.connect(refresh)
 refresh()
 if "--tests" in OS.get_cmdline_user_args() and "--titlebar-click-smoke" in OS.get_cmdline_user_args():
  load("res://scripts/tools/verify_window_frame.gd").run.call_deferred(self)
 if "--tests" in OS.get_cmdline_user_args() and "--toolbar-click-smoke" in OS.get_cmdline_user_args():
  load("res://scripts/tools/verify_toolbar_clicks.gd").run.call_deferred(self)
 if "--tests" in OS.get_cmdline_user_args() and "--transparency-smoke" in OS.get_cmdline_user_args():
  load("res://scripts/tools/verify_window_transparency.gd").run.call_deferred(self)
 if "--export-smoke" in OS.get_cmdline_user_args():
  var valid: bool = Game.model.roster.size() == 14 and FileAccess.file_exists("res://platform/windows/focus-worker.ps1") and not ocean.motion.config.is_empty() and Ocean.BACKGROUND != null and SceneAudio.WATER != null
  for fish in Game.model.roster:
   valid = valid and Portrait.texture_for(fish.id) != null
  valid = valid and FileAccess.file_exists("res://assets/production/aquarium_manifest.json")
  for group in ocean.frames.config.groups:
   for clip in ocean.frames.config.groups[group].clips:
    var sequence: Dictionary = ocean.frames.sequence(group,clip)
    for i in sequence.frames.size():
     valid = valid and ocean.frames.texture(group,clip,(i+.5)/sequence.frames.size()*float(sequence.duration)) != null
  for gear in ocean.frames.config.gear:
   valid = valid and ocean.frames.gear(gear) != null
  var floating: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/production/floating_manifest.json"))
  for asset in floating.assets:
   valid = valid and load("res://"+asset.path) is Texture2D
  valid = valid and FileAccess.file_exists('res://assets/production/mode2-v5/scene.animation.json') and FileAccess.file_exists('res://assets/production/mode2-v5/asset_manifest.json') and FileAccess.file_exists('res://data/fish-introductions.json')
  get_tree().quit(0 if valid else 1)
 if "--collection-capture" in OS.get_cmdline_user_args():
  call_deferred("collection_capture")
 if "--scene-capture" in OS.get_cmdline_user_args():
  call_deferred("scene_capture")
 if "--ui-smoke" in OS.get_cmdline_user_args():
  call_deferred("ui_smoke")

func make_theme() -> Theme:
 var t := Theme.new()
 var font := SystemFont.new()
 font.font_names = PackedStringArray(["Microsoft YaHei","Noto Sans SC","Noto Sans CJK SC","WenQuanYi Micro Hei","sans-serif"])
 t.default_font = font
 t.default_font_size = 14
 t.set_color("font_color","Label",Color("486575"))
 for type in ["Button","Window","ConfirmationDialog"]:
  t.set_color("font_color",type,Color("486575"))
 t.set_color("font_focus_color","Button",Color("486575"))
 t.set_stylebox("focus","Button",style(Color("dfedf3"),12))
 t.set_stylebox("normal","Button",style(Color("f6f7ed"),12))
 t.set_stylebox("hover","Button",style(Color("dfedf3"),12))
 t.set_stylebox("pressed","Button",style(Color("c8e0ed"),12))
 t.set_stylebox("disabled","Button",style(Color("e7eae4"),12))
 t.set_color("font_disabled_color","Button",Color("a4b4b3"))
 t.set_stylebox("panel","PanelContainer",style(Color("fffbee"),22))
 t.set_stylebox("panel","AcceptDialog",style(Color("fffbee"),18))
 t.set_stylebox("panel","ConfirmationDialog",style(Color("fffbee"),18))
 for entry in [['background','d6e3db'],['fill','85bace']]:
  var track := style(Color(entry[1]),4)
  track.set_content_margin_all(0)
  t.set_stylebox(entry[0],'ProgressBar',track)
 for state in ['normal','focus']:
  var input_skin := style(Color('edf5f5'),10)
  input_skin.content_margin_top = 8
  input_skin.content_margin_bottom = 8
  t.set_stylebox(state,'LineEdit',input_skin)
 t.set_color('font_color','LineEdit',Color('486575'))
 t.set_color('font_uneditable_color','LineEdit',Color('7b9297'))
 t.set_color('font_color','OptionButton',Color('486575'))
 t.set_color('font_color','CheckButton',Color('486575'))
 return t

func style(color: Color, radius: int) -> StyleBoxFlat:
 var result := StyleBoxFlat.new()
 result.bg_color = color
 result.set_corner_radius_all(radius)
 result.border_color = Color("bfd5df")
 result.set_border_width_all(1)
 result.content_margin_left = 16
 result.content_margin_right = 16
 result.content_margin_top = 12
 result.content_margin_bottom = 12
 return result

func label(text: String, font_size: int = 14, muted: bool = false) -> Label:
 var result := Label.new()
 result.text = text
 result.add_theme_font_size_override("font_size",font_size)
 if muted:
  result.add_theme_color_override("font_color",Color("7b9297"))
 return result

func paragraph(text: String, parent: Node, font_size: int = 13) -> Label:
 var result := label(text,font_size,true)
 result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 parent.add_child(result)
 return result

func button(text: String, parent: Node, callback: Callable) -> Button:
 var result := Button.new()
 result.text = text
 result.custom_minimum_size.y = 42
 result.pressed.connect(callback)
 parent.add_child(result)
 return result

func build_ui() -> void:
 var margin := MarginContainer.new()
 margin.name = "LayoutMargin"
 margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for edge in ["left","right","top","bottom"]:
  margin.add_theme_constant_override("margin_"+edge,24)
 margin.add_theme_constant_override("margin_top",60)
 add_child(margin)
 var root := VBoxContainer.new()
 root.add_theme_constant_override("separation",18)
 margin.add_child(root)
 var header := HBoxContainer.new()
 header.add_theme_constant_override("separation",12)
 root.add_child(header)
 var title_box := VBoxContainer.new()
 title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 header.add_child(title_box)
 title_box.add_child(label("DESKTOP FISHING",10,true))
 title_box.add_child(label("把忙碌，交给一片海",24))
 book_button = button("鱼类图鉴",header,func(): open_collection("book"))
 tank_button = button("精选鱼缸",header,func(): open_collection("tank"))
 var body := HBoxContainer.new()
 body.add_theme_constant_override("separation",20)
 body.size_flags_vertical = Control.SIZE_EXPAND_FILL
 root.add_child(body)
 ocean = Ocean.new()
 ocean.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 ocean.custom_minimum_size = Vector2(480,500)
 body.add_child(ocean)
 ocean.animation_finished.connect(refresh)
 ocean.splash.connect(func(): scene_audio.play("cast"))
 var ocean_margin := MarginContainer.new()
 ocean_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 ocean_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
 for edge in ["left","right","top","bottom"]:
  ocean_margin.add_theme_constant_override("margin_"+edge,20)
 ocean.add_child(ocean_margin)
 var overlay := VBoxContainer.new()
 overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
 ocean_margin.add_child(overlay)
 var clock_card := PanelContainer.new()
 clock_card.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
 var clock_style := style(Color("fffef2"),8)
 clock_style.border_color = Color("43b5e2")
 clock_style.set_border_width_all(2)
 clock_style.content_margin_left = 10
 clock_style.content_margin_right = 10
 clock_style.content_margin_top = 6
 clock_style.content_margin_bottom = 6
 clock_card.add_theme_stylebox_override("panel",clock_style)
 clock_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
 overlay.add_child(clock_card)
 var clock_box := VBoxContainer.new()
 clock_card.add_child(clock_box)
 scene_text = label("白昼的海",14)
 scene_text.add_theme_color_override("font_color",Color("426b89"))
 clock_box.add_child(scene_text)
 depth_text = label("0.0 米",24)
 depth_text.add_theme_color_override("font_color",Color("426b89"))
 clock_box.add_child(depth_text)
 var spacer := Control.new()
 spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
 overlay.add_child(spacer)
 overlay.add_child(label("海风很轻，今天也慢慢来。",12,true))
 var side_panel := PanelContainer.new()
 side_panel.custom_minimum_size.x = 310
 body.add_child(side_panel)
 var side := VBoxContainer.new()
 side.add_theme_constant_override("separation",10)
 var side_scroll := ScrollContainer.new()
 side_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 side_panel.add_child(side_scroll)
 side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 side.custom_minimum_size.x = 270
 side_scroll.add_child(side)
 side.add_child(label("慢慢工作，轻轻收获",11,true))
 status_title = label("准备出发",23)
 side.add_child(status_title)
 status_text = paragraph("",side)
 status_text.custom_minimum_size.y = 58
 var card := PanelContainer.new()
 focus_card = card
 card.add_theme_stylebox_override("panel",style(Color("edf4ef"),14))
 side.add_child(card)
 var time_box := VBoxContainer.new()
 time_box.add_theme_constant_override("separation",8)
 card.add_child(time_box)
 time_box.add_child(label("番茄钟 · 剩余时间",12,true))
 time_text = label("00:00",26)
 time_box.add_child(time_text)
 progress = ProgressBar.new()
 progress.max_value = 100
 progress.show_percentage = false
 progress.custom_minimum_size.y = 8
 time_box.add_child(progress)
 time_box.add_child(label("完成后手动起竿 · 暂停不计时",11,true))
 var actions := HBoxContainer.new()
 fishing_actions = actions
 actions.add_theme_constant_override("separation",8)
 side.add_child(actions)
 cast_button = button("放竿开始",actions,func(): perform_fishing("cast"))
 reel_button = button("收杆看看",actions,func(): perform_fishing("reel"))
 cast_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 reel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 cast_button.add_theme_stylebox_override("normal",style(Color("d1e5da"),12))
 reel_button.add_theme_stylebox_override("normal",style(Color("efdfd2"),12))
 pause_button = button("暂停",side,func(): handle(Game.toggle_pause()))
 skip_button = button("跳过动画",side,func(): ocean.skip())
 skip_button.visible = false
 catch_box = VBoxContainer.new()
 catch_box.add_theme_constant_override("separation",8)
 side.add_child(catch_box)
 feedback_toast = paragraph("",side,12)
 feedback_toast.add_theme_color_override("font_color",Color("477c66"))
 feedback_toast.visible = false
 notice = paragraph("",side,12)
 notice.add_theme_color_override("font_color",Color("9b745c"))
 var side_spacer := Control.new()
 side_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
 side.add_child(side_spacer)
 sound_button = button("声音：关闭",side,func(): handle(Game.set_sound_enabled(not Game.state.sound_enabled)))
 timer_setup = VBoxContainer.new()
 timer_setup.add_theme_constant_override("separation",6)
 side.add_child(timer_setup)
 paragraph("设定专注时长 · 15–120 分钟",timer_setup,11)
 duration_input = SpinBox.new()
 duration_input.min_value = 15
 duration_input.max_value = 120
 duration_input.step = 1
 duration_input.suffix = "分钟"
 duration_input.value = 25
 timer_setup.add_child(duration_input)
 duration_input.value_changed.connect(func(value): handle(Game.set_duration(int(value))))
 var presets := HBoxContainer.new()
 timer_setup.add_child(presets)
 for minutes in [25,45,60]:
  var preset := button(str(minutes)+" 分",presets,func():
   handle(Game.set_duration(minutes))
   refresh())
  preset.set_meta('duration_preset',true)
 pool_preview = paragraph("",timer_setup,11)
 side.move_child(timer_setup,side.get_children().find(focus_card))
 saved_label = paragraph("",side,11)
 var maintenance := HBoxContainer.new()
 side.add_child(maintenance)
 button("检测与诊断",maintenance,show_diagnostics)
 button("保存退出",maintenance,Game.request_exit)
 paragraph("前台、图鉴与无键鼠操作都继续计时。暂停、锁屏、休眠与退出期间不累计。F8 保存退出。",side,11)
 var footer := HBoxContainer.new()
 root.add_child(footer)
 var version := label("桌面钓鱼 · 0.8.1-preview · 海边日常",11,true)
 version.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 footer.add_child(version)
 button("场景悬浮",footer,func(): layouts.apply("scene"))
 button("极简悬浮",footer,func(): layouts.apply("mini"))
 footer.add_child(label("不记录按键内容或窗口标题",11,true))
 build_dialogs()

func _input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F8:
  Game.request_exit()

func show_diagnostics() -> void:
 diagnostic_dialog.force_native = layouts != null and layouts.mode != 'full'
 diagnostic_dialog.dialog_text = Game.diagnostic_text() + "\n\n检测异常会自动重试；恢复后不补计中断时间。"
 diagnostic_dialog.popup_centered(Vector2i(460,360))

func build_dialogs() -> void:
 diagnostic_dialog = AcceptDialog.new()
 diagnostic_dialog.visible = false
 diagnostic_dialog.title = "运行诊断"
 diagnostic_dialog.ok_button_text = "关闭"
 diagnostic_dialog.add_button("复制诊断",false,"copy")
 diagnostic_dialog.add_button("重试检测",false,"retry")
 diagnostic_dialog.custom_action.connect(func(action):
  if action == "copy":
   DisplayServer.clipboard_set(Game.diagnostic_text())
  elif action == "retry":
   Game.retry_detection()
   show_diagnostics())
 add_child(diagnostic_dialog)
 collection = Window.new()
 collection.visible = false
 collection.title = "收藏"
 collection.theme = theme
 collection.borderless = true
 collection.transparent = true
 collection.transparent_bg = true
 collection.size = Vector2i(750,620)
 collection.min_size = Vector2i(560,420)
 collection.transient = true
 collection.exclusive = true
 collection.close_requested.connect(close_collection)
 collection.window_input.connect(func(event):
  if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
   close_collection())
 add_child(collection)
 var shell := PanelContainer.new()
 shell.name = 'CollectionShell'
 shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var shell_skin := style(Color('fffbee'),22)
 shell_skin.border_color = Color('99c6d8')
 shell_skin.set_border_width_all(2)
 shell_skin.set_content_margin_all(0)
 shell.add_theme_stylebox_override('panel',shell_skin)
 collection.add_child(shell)
 var margin := MarginContainer.new()
 margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for edge in ["left","right","top","bottom"]:
  margin.add_theme_constant_override("margin_"+edge,20)
 shell.add_child(margin)
 var box := VBoxContainer.new()
 box.add_theme_constant_override("separation",12)
 margin.add_child(box)
 var header := HBoxContainer.new()
 box.add_child(header)
 collection_title = label("",24)
 collection_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 header.add_child(collection_title)
 collection_title.mouse_filter = Control.MOUSE_FILTER_STOP
 collection_title.mouse_default_cursor_shape = Control.CURSOR_MOVE
 collection_title.gui_input.connect(func(e):
  if e is InputEventMouseButton and e.pressed and e.button_index==MOUSE_BUTTON_LEFT:
   collection.start_drag())
 collection_close = button("关闭",header,close_collection)
 var navigation := HBoxContainer.new()
 navigation.add_theme_constant_override('separation',8)
 box.add_child(navigation)
 for entry in [['book','鱼类图鉴'],['tank','精选鱼缸']]:
  var key: String = entry[0]
  var tab: Button = button(entry[1],navigation,func(): open_collection(key))
  tab.icon = load('res://assets/production/ui/'+key+'.svg')
  tab.expand_icon = true
  tab.add_theme_constant_override('icon_max_width',20)
  tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  collection_tabs[key] = tab
 book_filter = OptionButton.new()
 book_filter.custom_minimum_size.y = 36
 for state in ['normal','hover','pressed']:
  var filter_skin := style(Color('edf5f5'),10)
  filter_skin.content_margin_top = 6
  filter_skin.content_margin_bottom = 6
  book_filter.add_theme_stylebox_override(state,filter_skin)
 for entry in [["全部分组","all"],["A 类 · 15–29 分钟","A"],["B 类 · 30–59 分钟","B"],["C 类 · 60–120 分钟","C"],["特殊事件","event"]]:
  book_filter.add_item(entry[0])
  book_filter.set_item_metadata(book_filter.item_count-1,entry[1])
 book_filter.item_selected.connect(func(index):
  book_group = book_filter.get_item_metadata(index)
  panel_signature = ""
  render_collection())
 box.add_child(book_filter)
 collection_description = paragraph("",box)
 collection_progress = ProgressBar.new()
 collection_progress.show_percentage = false
 collection_progress.custom_minimum_size.y = 7
 collection_progress.step = .01
 box.add_child(collection_progress)
 collection_notice = paragraph("",box,12)
 collection_notice.add_theme_color_override("font_color",Color("9b745c"))
 collection_notice.visible = false
 collection_feedback = paragraph("",box,12)
 collection_feedback.add_theme_color_override("font_color",Color("477c66"))
 collection_feedback.visible = false
 aquarium_view = Aquarium.new()
 aquarium_view.custom_minimum_size = Vector2(0,190)
 aquarium_view.visible = false
 aquarium_view.fish_selected.connect(select_tank_fish)
 box.add_child(aquarium_view)
 var scroll := ScrollContainer.new()
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 scroll.custom_minimum_size.y = 100
 scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 box.add_child(scroll)
 collection_grid = GridContainer.new()
 collection_grid.columns = 3
 collection_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 collection_grid.add_theme_constant_override("h_separation",12)
 collection_grid.add_theme_constant_override("v_separation",12)
 scroll.add_child(collection_grid)
 collection.size_changed.connect(update_collection_layout)
 update_collection_layout()
 confirmation = ConfirmationDialog.new()
 confirmation.visible = false
 confirmation.title = "确认操作"
 confirmation.theme = theme
 confirmation.ok_button_text = "确认"
 confirmation.cancel_button_text = "取消"
 confirmation.min_size = Vector2i(420,180)
 confirmation.dialog_autowrap = true
 confirmation.transient = true
 confirmation.exclusive = true
 add_child(confirmation)
 confirmation.confirmed.connect(func():
  var action: Callable = confirm_action
  confirm_action = Callable()
  if action.is_valid():
   action.call())
 confirmation.canceled.connect(func(): confirm_action = Callable())

func perform_fishing(action: String) -> void:
 if ocean.is_busy():
  return
 if action == "reel" and Game.state.cast and not Game.model.completed(Game.state):
  ask("番茄钟尚未完成。提前起竿将判定失败，本次无法获得鱼获。确定结束？",func():
   var failed: Dictionary = Game.fail_challenge()
   handle(failed)
   if failed.ok:
    show_feedback("本次挑战失败，没有鱼获。")
   refresh(),"确认失败并起竿")
  return
 var result: Dictionary = Game.cast_line() if action == "cast" else Game.reel_line()
 handle(result)
 if result.ok:
  ocean.play(action)
  if action == "reel":
   scene_audio.play("reel")
  refresh()

func handle(result: Dictionary) -> void:
 action_error = ""
 if not result.ok:
  var messages := {"full":"鱼缸已满（6 / 6），请选择替换。","save_failed":"保存失败，操作未完成。请检查磁盘空间和权限后重试。","blocked":"存档不可用，已暂停操作。请打开检测与诊断查看。","pending":"请先安置本次鱼获。","no_catch":"当前没有待安置的鱼获。","unknown":"这条鱼已不在鱼缸中，请重新选择。","not_cast":"请先放下鱼钩。","already_cast":"鱼钩已经放下，请稍后收杆。","too_early":"番茄钟尚未完成，提前起竿将失败。","active_challenge":"挑战已开始，时长不能修改。","system_paused":"锁屏检测尚未就绪或系统仍锁定，暂时无法继续。","invalid_setting":"时长需为15–120分钟。"}
  action_error = messages.get(result.get("reason",""),"操作未完成，请重试。")
 update_notices()
 if layouts != null and layouts.mode != 'full' and not result.ok and not collection.visible and not confirmation.visible:
  layouts.open_settings()

func update_notices() -> void:
 var message: String = Game.warning if not Game.warning.is_empty() else action_error
 notice.text = message
 notice.visible = not message.is_empty()
 collection_notice.text = message
 collection_notice.visible = not message.is_empty()

func ask(text: String, action: Callable, confirm_text: String = "确认") -> void:
 confirmation.hide()
 confirmation.force_native = layouts != null and layouts.mode != "full"
 confirm_action = action
 var parent: Node = collection if collection.visible else self
 if confirmation.get_parent() != parent:
  confirmation.reparent(parent)
 confirmation.dialog_text = text
 confirmation.ok_button_text = confirm_text
 confirmation.popup_centered()

func refresh() -> void:
 if status_title == null:
  return
 var s: Dictionary = Game.state
 var reason: String = Game.pause_reason()
 var status: Array = STATUS.get(reason,STATUS.ready)
 status_title.text = "轻轻放钩…" if ocean.motion.active == "cast" else ("这次会遇见谁？" if ocean.motion.active == "reel" else status[0])
 status_text.text = status[1]
 if reason == "paused":
  var causes := {'manual':'手动暂停','locked':'系统锁屏','sleep':'休眠或时钟中断','system':'系统状态中断','restart':'重新打开游戏','detection':'锁屏检测暂不可用'}
  status_text.text = str(causes.get(s.pause_cause,'暂停'))+" · 剩余时间保留，点击继续恢复。"
 duration_input.set_value_no_signal(s.duration_minutes)
 duration_input.editable = not Game.blocked and not s.cast and s.pending_catch.is_empty()
 for child in duration_input.get_parent().get_children():
  if child is HBoxContainer:
   for item in child.get_children():
    if item.has_meta('duration_preset'):
     item.disabled = not duration_input.editable
 pool_preview.text = Game.model.group_label(s.duration_minutes)+" · 仅从本组抽取\n"+"、".join(Game.model.fish_pool(s.duration_minutes).map(func(f): return f.name))
 pause_button.text = "继续" if s.paused else "暂停"
 pause_button.disabled = Game.blocked or not s.cast or Game.model.completed(s)
 saved_label.text = "最近保存：" + Game.last_saved + (" · 保存失败" if Game.save_failed else "")
 var ratio: float = clampf(s.focus_seconds/(s.duration_minutes*60.0),0,1)
 var depth: float = ratio*200.0
 var remaining: int = int(ceil(Game.remaining_seconds()))
 depth_text.text = "%02d:%02d" % [remaining/60,remaining%60]
 time_text.text = depth_text.text
 progress.value = ratio*100
 focus_card.visible = s.pending_catch.is_empty()
 fishing_actions.visible = s.pending_catch.is_empty()
 status_text.custom_minimum_size.y = 38 if s.pending_catch.is_empty() else 0
 timer_setup.visible = s.pending_catch.is_empty()
 pause_button.visible = s.cast
 var hour: int = Time.get_datetime_dict_from_system().hour
 ocean.depth = depth
 ocean.cast = s.cast
 ocean.night = hour < 6 or hour >= 18
 ocean.working = reason == "working"
 ocean.show_catch(not s.pending_catch.is_empty())
 ocean.queue_redraw()
 scene_text.text = ("夜晚的海" if ocean.night else "白昼的海") + " · " + Game.model.group_label(s.duration_minutes)
 cast_button.disabled = ocean.is_busy() or Game.blocked or s.cast or not s.pending_catch.is_empty()
 reel_button.disabled = ocean.is_busy() or Game.blocked or not s.cast
 var unavailable := "存档不可用，请查看检测与诊断。" if Game.blocked else ("动画播放中，可选择跳过动画。" if ocean.is_busy() else "")
 cast_button.tooltip_text = unavailable if not unavailable.is_empty() else ("请先安置本次鱼获。" if not s.pending_catch.is_empty() else ("番茄钟进行中，完成后再起竿。" if s.cast else "按设定时长开始番茄钟。"))
 reel_button.text = "起竿揭晓" if Game.model.completed(s) else "提前起竿"
 reel_button.tooltip_text = unavailable if not unavailable.is_empty() else ("提前起竿将失败，会先询问确认。" if s.cast and not Game.model.completed(s) else "完成后起竿揭晓本组鱼获。")
 skip_button.visible = ocean.is_busy()
 catch_box.visible = ocean.motion.active != "reel"
 sound_button.text = "声音：开启" if s.sound_enabled else "声音：关闭"
 sound_button.disabled = Game.blocked
 scene_audio.set_enabled(s.sound_enabled)
 if reason == "completed" and completion_notified != s.session_id:
  completion_notified = s.session_id
  scene_audio.play("reel")
 book_button.text = "图鉴 %d / %d" % [s.encyclopedia.size(),Game.model.roster.size()]
 tank_button.text = "鱼缸 %d / 6" % s.aquarium.size()
 update_notices()
 var signature: String = JSON.stringify([s.pending_catch,s.aquarium.size(),Game.blocked])
 if signature != catch_signature:
  catch_signature = signature
  render_catch()
 if collection.visible:
  render_collection()

func clear_children(parent: Node) -> void:
 for child in parent.get_children():
  parent.remove_child(child)
  child.queue_free()

func portrait(id: String, hidden: bool = false, height: float = 96) -> Control:
 var view = Portrait.new()
 view.species_id = id
 view.silhouette = hidden
 view.custom_minimum_size = Vector2(96,height)
 var canvas := PanelContainer.new()
 var skin := style(Color('eaf5f5'),12)
 skin.border_color = Color('cfe3e6')
 skin.set_content_margin_all(5)
 canvas.add_theme_stylebox_override('panel',skin)
 canvas.add_child(view)
 return canvas

func select_tank_fish(catch_id: String) -> void:
 var index: int = Game.model.find_catch(Game.state.aquarium,catch_id)
 if index < 0:
  return
 var c: Dictionary = Game.state.aquarium[index]
 var f: Dictionary = Game.model.species(c.species_id)
 collection_description.text = tank_description() + "\n已选 %s · %.1f cm · 在下方管理这条鱼" % [f.name,c.length_cm]
 var card_panel: Control = collection_grid.get_child(index)
 card_panel.get_child(0).get_children().back().grab_focus()

func render_catch() -> void:
 if reveal_tween != null and reveal_tween.is_running():
  reveal_tween.kill()
 catch_box.scale = Vector2.ONE
 catch_box.modulate.a = 1.0
 clear_children(catch_box)
 var c: Dictionary = Game.state.pending_catch
 if c.is_empty():
  catch_box.add_child(label("下一次相遇",13))
  paragraph("完成番茄钟后，从设定时长对应的专属鱼池抽取。发现过的鱼会留在图鉴中。",catch_box,12)
  return
 var f: Dictionary = Game.model.species(c.species_id)
 catch_box.add_child(label("鱼获揭晓 · " + RARITY.get(f.rarity,f.rarity),11,true))
 catch_box.add_child(portrait(f.id,false,112))
 catch_box.add_child(label(f.name,22))
 if c.get("first_discovery",false):
  catch_box.add_child(label("✦ 首次发现 · 图鉴已点亮",12,true))
 if c.get("new_record",false):
  var previous: float = float(c.get("previous_record_cm",0.0))
  var record_text := "✦ 新纪录 · %.1f cm" % c.length_cm if previous <= 0.0 else "✦ 新纪录 · %.1f → %.1f cm" % [previous,c.length_cm]
  paragraph(record_text,catch_box,12)
 catch_box.add_child(label("%.1f cm · 专注 %d 分钟" % [c.length_cm,int(c.duration_minutes)],13,true) if c.has("duration_minutes") else label("%.1f cm · 旧版收藏" % c.length_cm,13,true))
 if Game.state.aquarium.size() >= 6:
  paragraph("鱼缸已满（6 / 6）。可选择一条替换，或放生本次鱼获；取消替换会保留双方。",catch_box,12)
 var row := HBoxContainer.new()
 row.add_theme_constant_override("separation",8)
 catch_box.add_child(row)
 var keep := button("选择替换" if Game.state.aquarium.size() >= 6 else "收进鱼缸",row,func():
  if Game.state.aquarium.size() >= 6:
   open_collection("tank",true)
  else:
   settle_catch("keep"))
 var release := button("放生",row,func(): ask("放生这次鱼获？图鉴次数和体长纪录会保留。",func(): settle_catch("release"),"确认放生"))
 keep.disabled = Game.blocked
 release.disabled = Game.blocked
 catch_box.scale = Vector2(0.96,0.96)
 catch_box.modulate.a = 0.0
 reveal_tween = create_tween().set_parallel(true)
 reveal_tween.tween_property(catch_box,"scale",Vector2.ONE,0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
 reveal_tween.tween_property(catch_box,"modulate:a",1.0,0.22)

func settle_catch(action: String, target_id: String = "") -> Dictionary:
 var c: Dictionary = Game.state.pending_catch.duplicate(true)
 if c.is_empty():
  return {"ok":false,"reason":"no_catch"}
 var fish: Dictionary = Game.model.species(c.species_id)
 var replaced_name := ""
 if action == "replace":
  var index: int = Game.model.find_catch(Game.state.aquarium,target_id)
  if index >= 0:
   replaced_name = Game.model.species(Game.state.aquarium[index].species_id).get("name","")
 var result: Dictionary = Game.settle(action,target_id)
 handle(result)
 if not result.ok:
  return result
 if action == "keep":
  show_feedback("%s 已入住鱼缸 · %d / 6" % [fish.name,Game.state.aquarium.size()])
  animate_tank_button()
 elif action == "replace":
  show_feedback("%s 替换了 %s · 鱼缸 %d / 6" % [fish.name,replaced_name,Game.state.aquarium.size()])
  animate_tank_button()
 elif action == "release":
  show_feedback("%s 已放生 · 图鉴纪录已保留" % fish.name)
 return result

func show_feedback(message: String) -> void:
 if feedback_toast == null:
  return
 feedback_toast.text = "✓ " + message
 feedback_toast.visible = true
 feedback_toast.modulate.a = 1.0
 collection_feedback.text = feedback_toast.text
 collection_feedback.visible = collection.visible
 collection_feedback.modulate.a = 1.0
 if feedback_tween != null and feedback_tween.is_running():
  feedback_tween.kill()
 feedback_tween = create_tween()
 feedback_tween.tween_interval(2.4)
 feedback_tween.tween_property(feedback_toast,"modulate:a",0.0,0.4)
 feedback_tween.parallel().tween_property(collection_feedback,"modulate:a",0.0,0.4)
 feedback_tween.tween_callback(func():
  feedback_toast.visible = false
  collection_feedback.visible = false)

func animate_tank_button() -> void:
 if tank_button == null:
  return
 if tank_tween != null and tank_tween.is_running():
  tank_tween.kill()
 tank_button.pivot_offset = tank_button.size / 2.0
 tank_button.scale = Vector2.ONE
 tank_tween = create_tween()
 tank_tween.tween_property(tank_button,"scale",Vector2(1.08,1.08),0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
 tank_tween.tween_property(tank_button,"scale",Vector2.ONE,0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)

func open_collection(mode: String, replace: bool = false) -> void:
 collection.hide()
 collection.force_native = layouts != null and layouts.mode != "full"
 panel_mode = mode
 replacing = replace and mode == "tank" and not Game.state.pending_catch.is_empty() and not Game.state.aquarium.is_empty()
 collection_feedback.visible = false
 panel_signature = ""
 render_collection()
 update_notices()
 update_collection_layout()
 var area: Rect2i = layouts.work_area()
 collection.size = Vector2i(mini(collection.size.x,area.size.x-24),mini(collection.size.y,area.size.y-24))
 collection.popup_centered()

func close_collection() -> void:
 confirmation.hide()
 confirm_action = Callable()
 replacing = false
 collection.hide()

func update_collection_layout() -> void:
 collection_grid.columns = 2 if collection.size.x < 720 else 3
 aquarium_view.visible = panel_mode == "tank" and collection.size.y >= 520
 aquarium_view.custom_minimum_size.y = clampf(float(collection.size.y - 420) * 0.4 + 110.0,110.0,190.0)

func tank_description() -> String:
 var summary := "鱼缸 %d / 6 · 放生会保留图鉴纪录。" % Game.state.aquarium.size()
 if replacing:
  var incoming: Dictionary = Game.model.species(Game.state.pending_catch.get("species_id",""))
  summary += "\n为 %s 选择替换对象。取消替换会保留原鱼和本次鱼获。" % incoming.get("name","本次鱼获")
 elif Game.state.aquarium.size() >= 6:
  summary += "\n鱼缸已满，新鱼获可通过替换入住。"
 return summary

func release_tank_fish(catch_id: String) -> void:
 var index: int = Game.model.find_catch(Game.state.aquarium,catch_id)
 var fish_name: String = Game.model.species(Game.state.aquarium[index].species_id).get("name","") if index >= 0 else ""
 var result: Dictionary = Game.remove_from_tank(catch_id)
 handle(result)
 if result.ok:
  show_feedback("%s 已放生 · 图鉴纪录已保留" % fish_name)

func card() -> VBoxContainer:
 var panel := PanelContainer.new()
 panel.custom_minimum_size.x = 205
 panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 var skin := style(Color('fffdf5'),16)
 skin.border_color = Color('bdd6df')
 skin.set_content_margin_all(12)
 panel.add_theme_stylebox_override('panel',skin)
 collection_grid.add_child(panel)
 var box := VBoxContainer.new()
 box.add_theme_constant_override("separation",8)
 panel.add_child(box)
 return box

func render_collection() -> void:
 var s: Dictionary = Game.state
 var signature: String = JSON.stringify([panel_mode,book_group,replacing,s.encyclopedia,s.aquarium,s.pending_catch,Game.blocked])
 if signature == panel_signature:
  return
 panel_signature = signature
 clear_children(collection_grid)
 update_collection_layout()
 aquarium_view.catches = s.aquarium.duplicate(true)
 aquarium_view.queue_redraw()
 book_filter.visible = panel_mode == 'book'
 for key in collection_tabs:
  var active: bool = key == panel_mode
  collection_tabs[key].disabled = active
  collection_tabs[key].add_theme_stylebox_override('disabled',style(Color('dceef3'),12))
 collection_progress.max_value = Game.model.roster.size() if panel_mode == 'book' else 6
 collection_progress.value = s.encyclopedia.size() if panel_mode == 'book' else s.aquarium.size()
 collection_title.text = "鱼类图鉴" if panel_mode == "book" else "精选鱼缸"
 collection_close.text = "取消替换" if replacing else "关闭"
 collection_description.text = "已发现 %d / %d · 每次相遇都留下纪录。" % [s.encyclopedia.size(),Game.model.roster.size()] if panel_mode == "book" else tank_description()
 if panel_mode == "book":
  var ordered: Array = Game.model.roster.duplicate()
  ordered.sort_custom(func(a,b): return str(a.focus_group) < str(b.focus_group))
  for f in ordered:
   if book_group != "all" and f.focus_group != book_group:
    continue
   var box: VBoxContainer = card()
   var record: Dictionary = s.encyclopedia.get(f.id,{})
   var minutes: int = {"A":25,"B":45,"C":60,"event":0}[f.focus_group]
   paragraph("特殊事件 · 暂未开放" if minutes == 0 else Game.model.group_label(minutes)+" · %.2f%%" % (Game.model.fish_probability(f.id,minutes)*100),box,11)
   box.add_child(portrait(f.id,record.is_empty()))
   if Portrait.texture_for(f.id) == null:
    box.add_child(label("插画待制作",11,true))
   box.add_child(label(f.name if not record.is_empty() else '尚未发现',16))
   if not record.is_empty():
    var badge := label(str(RARITY.get(f.rarity,f.rarity)),11)
    badge.add_theme_color_override('font_color',Color('5d958e'))
    box.add_child(badge)
   if record.is_empty():
    paragraph("尚未解锁\n等待一次惊喜相遇",box,12)
   else:
    paragraph("相遇 %d 次\n最大体长 %.1f cm" % [record.count,record.record_cm],box,12)
    var entry: Dictionary = layouts.catch_popup.introductions.get(f.id,{})
    paragraph('海洋小百科 · '+str(entry.get('fact','')),box,11)
  return
 if s.aquarium.is_empty():
  paragraph("鱼缸还很安静。收杆后选择收进鱼缸，邀请第一位朋友。",card())
 for c in s.aquarium:
  var box: VBoxContainer = card()
  var f: Dictionary = Game.model.species(c.species_id)
  box.add_child(portrait(f.id,false,64))
  if Portrait.texture_for(f.id) == null:
   box.add_child(label("插画待制作",11,true))
  box.add_child(label(f.name,16))
  box.add_child(label("%.1f cm" % c.length_cm,12,true))
  var catch_id: String = c.catch_id
  var chosen = button("替换这条鱼" if replacing else "放生",box,func():
   if replacing:
    ask("放生 %s（%.1f cm），让本次鱼获住进来？" % [f.name,c.length_cm],func():
     var result: Dictionary = settle_catch("replace",catch_id)
     if result.ok:
      replacing = false
      close_collection(),"确认替换")
   else:
    ask("放生 %s（%.1f cm）？图鉴纪录会保留。" % [f.name,c.length_cm],func(): release_tank_fish(catch_id),"确认放生"))
  chosen.disabled = Game.blocked

func ui_smoke() -> void:
 await get_tree().process_frame
 await get_tree().process_frame
 var layout_root: Control = get_node("LayoutMargin").get_child(0)
 assert(layout_root.get_combined_minimum_size().y + 48 <= get_window().size.y)
 # Isolated test save path; no player save writes or Windows sampling.
 var test_path: String = "user://ui-test-%s.json" % Game.model.new_id()
 Game.save_path = test_path
 Game.state = Game.model.fresh_state()
 refresh()
 handle({"ok":false,"reason":"full"})
 refresh()
 assert(notice.visible and notice.text.contains("鱼缸已满"))
 handle({"ok":true})
 assert(not notice.visible)
 open_collection("tank",true)
 assert(not replacing and collection_grid.get_child_count() == 1)
 handle({"ok":false,"reason":"save_failed"})
 assert(collection_notice.visible and collection_notice.text.contains("保存失败"))
 handle({"ok":true})
 collection.size = Vector2i(560,420)
 update_collection_layout()
 assert(collection_grid.columns == 2 and not aquarium_view.visible)
 collection.size = Vector2i(750,620)
 update_collection_layout()
 assert(collection_grid.columns == 3)
 close_collection()
 assert(not cast_button.disabled)
 assert(reel_button.disabled)
 assert(Game.model.cast_line(Game.state).ok)
 refresh()
 assert(cast_button.disabled and not reel_button.disabled)
 Game.state.focus_seconds = Game.state.duration_minutes*60
 assert(Game.model.reel_line(Game.state,12,Game.rng).ok)
 refresh()
 assert(cast_button.disabled and reel_button.disabled)
 var reveal_copy: String = ""
 for child in catch_box.get_children():
  if child is Label:
   reveal_copy += child.text + "\n"
 assert(reveal_copy.contains("首次发现") and reveal_copy.contains("新纪录"))
 assert(settle_catch("keep").ok)
 assert(feedback_toast.visible and feedback_toast.text.contains("已入住鱼缸"))
 open_collection("tank")
 assert(collection_grid.get_child_count() == 1)
 collection.hide()
 open_collection("book")
 assert(collection_grid.get_child_count() == 14)
 collection.hide()
 assert(Game.model.cast_line(Game.state).ok)
 Game.state.focus_seconds = Game.state.duration_minutes*60
 assert(Game.model.reel_line(Game.state,12,Game.rng).ok)
 for i in range(5):
  var existing: Dictionary = Game.state.pending_catch.duplicate(true)
  existing.catch_id = "ui-old-%d" % i
  Game.state.aquarium.append(existing)
 refresh()
 await get_tree().process_frame
 await get_tree().process_frame
 var catch_actions: Control = catch_box.get_children().back()
 var sidebar_scroll: Control = catch_box.get_parent().get_parent()
 assert(sidebar_scroll.get_global_rect().encloses(catch_actions.get_global_rect()))
 open_collection("tank",true)
 assert(collection_description.text.contains("6 / 6") and collection_close.text == "取消替换")
 Game.blocked = true
 refresh()
 for entry in collection_grid.get_children():
  assert(entry.get_child(0).get_children().back().disabled)
 Game.blocked = false
 refresh()
 var original: Dictionary = Game.state.duplicate(true)
 close_collection()
 assert(Game.state == original and not replacing)
 open_collection("tank",true)
 var target_panel: Node = collection_grid.get_child(2)
 var target_button: Button = target_panel.get_child(0).get_children().back()
 target_button.pressed.emit()
 assert(confirmation.visible)
 assert(confirmation.ok_button_text == "确认替换")
 confirmation.hide()
 confirmation.canceled.emit()
 assert(Game.state == original)
 Game.save_path = "user://missing-ui-%s/save.json" % Game.model.new_id()
 target_button.pressed.emit()
 confirmation.hide()
 confirmation.confirmed.emit()
 assert(Game.state == original and collection.visible and replacing)
 assert(collection_notice.visible and not collection_notice.text.is_empty())
 assert(notice.visible and not notice.text.is_empty())
 Game.save_path = test_path
 target_button.pressed.emit()
 confirmation.hide()
 confirmation.confirmed.emit()
 assert(Game.state.pending_catch.is_empty())
 assert(Game.state.aquarium.size() == 6)
 assert(feedback_toast.visible and feedback_toast.text.contains("替换了"))
 assert(not collection.visible)
 for suffix in ["", ".bak", ".tmp"]:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path + suffix))
 collection.hide()
 duration_input.value = 45
 assert(Game.state.duration_minutes == 45)
 scene_audio.set_enabled(false)
 assert(Game.set_sound_enabled(true).ok and Game.state.sound_enabled)
 assert(Game.set_sound_enabled(false).ok and not scene_audio.enabled)
 assert(Game.model.cast_line(Game.state).ok)
 Game.state.focus_seconds = Game.state.duration_minutes*60
 refresh()
 perform_fishing("reel")
 var caught: Dictionary = Game.state.pending_catch.duplicate(true)
 assert(ocean.is_busy() and not catch_box.visible and reel_button.disabled)
 perform_fishing("reel")
 assert(Game.state.pending_catch == caught)
 ocean.skip()
 assert(not ocean.is_busy() and catch_box.visible)
 assert(settle_catch("release").ok)
 assert(feedback_toast.visible and feedback_toast.text.contains("图鉴纪录已保留"))
 show_diagnostics()
 assert(diagnostic_dialog.visible)
 assert(diagnostic_dialog.dialog_text.contains("45 分钟"))
 diagnostic_dialog.hide()
 for suffix in ["", ".bak", ".tmp"]:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path + suffix))
 if "--capture-ui" in OS.get_cmdline_user_args():
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png("user://stage1-ui.png")
 await get_tree().create_timer(0.2).timeout
 print("Godot UI smoke: empty/full tank, small layout, visible errors, blocked controls, failed-save preservation, cancel and replacement passed")
 get_tree().quit()

func scene_capture() -> void:
 OS.low_processor_usage_mode = false
 Game.state = Game.model.fresh_state()
 Game.model.cast_line(Game.state)
 Game.state.focus_seconds = 1200.0
 Game.focus_status = {"supported":true,"foreground":false,"locked":false,"idle_seconds":0}
 refresh()
 ocean.night = "--night" in OS.get_cmdline_user_args()
 scene_text.text = ("夜晚的海" if ocean.night else "白昼的海") + " · 浅海"
 if "--cast-pose" in OS.get_cmdline_user_args():
  ocean.play("cast")
  ocean.motion.advance(.45)
 elif "--reel-pose" in OS.get_cmdline_user_args():
  ocean.play("reel")
  ocean.motion.advance(.5)
 await get_tree().process_frame
 await get_tree().process_frame
 RenderingServer.force_draw()
 var name: String = "stage2-night" if ocean.night else "stage2-day"
 if "--cast-pose" in OS.get_cmdline_user_args():
  name = "stage2-cast"
 elif "--reel-pose" in OS.get_cmdline_user_args():
  name = "stage2-reel"
 if "--small" in OS.get_cmdline_user_args():
  name += "-small"
 var destination: String = "res://docs/qa/stage4/" + name.replace("stage2-","") + ".png" if "--stage4" in OS.get_cmdline_user_args() else "user://" + name + ".png"
 get_viewport().get_texture().get_image().save_png(destination)
 get_tree().quit()

func collection_capture() -> void:
 OS.low_processor_usage_mode = false
 Game.state = Game.model.fresh_state()
 var ids: Array = Game.model.roster.map(func(f): return f.id)
 if "--showcase" in OS.get_cmdline_user_args():
  ids = ["fish_001_clownfish","creature_013_jellyfish","fish_008_yellowfin_tuna","fish_004_seahorse","creature_014_cuttlefish","fish_012_star_wish_fish"]
 for i in range(6):
  var id: String = ids[i%ids.size()]
  Game.state.aquarium.append({"catch_id":"qa-%d"%i,"species_id":id,"length_cm":12.0+i,"depth":80.0,"caught_at":"QA"})
  Game.state.encyclopedia[id] = {"count":2,"record_cm":17.0}
 Game.state.pending_catch = {"catch_id":"qa-pending","species_id":ids[0],"length_cm":18.0,"depth":20.0,"caught_at":"QA","first_discovery":true,"new_record":true}
 for fish in Game.model.roster:
  Game.state.encyclopedia[fish.id] = {"count":2,"record_cm":17.0}
 if "--undiscovered" in OS.get_cmdline_user_args():
  Game.state.encyclopedia = {}
 if "--empty" in OS.get_cmdline_user_args():
  Game.state = Game.model.fresh_state()
 refresh()
 var mode := "book" if "--book" in OS.get_cmdline_user_args() else "tank"
 if "--samples" in OS.get_cmdline_user_args():
  get_node("LayoutMargin").hide()
  var board := VBoxContainer.new()
  board.position = Vector2(24,24)
  add_child(board)
  board.add_child(label("V2.6 全生物 · 32 / 48 / 64 / 96 px",22))
  var sample_ids: Array = ids.slice(7,14) if "--page2" in OS.get_cmdline_user_args() else ids.slice(0,7)
  for color in [Color("91c8d1") if "--blue" in OS.get_cmdline_user_args() else Color("fffbee")]:
   var row := GridContainer.new()
   row.columns = 3
   row.add_theme_constant_override("h_separation",12)
   row.add_theme_constant_override("v_separation",8)
   board.add_child(row)
   for id in sample_ids:
    var panel := PanelContainer.new()
    panel.add_theme_stylebox_override("panel",style(color,12))
    row.add_child(panel)
    var sample_box := VBoxContainer.new()
    panel.add_child(sample_box)
    sample_box.add_child(label(Game.model.species(id).name,16))
    var samples := HBoxContainer.new()
    sample_box.add_child(samples)
    for pixels in [32,48,64,96]:
     var sample = portrait(id,false,pixels)
     sample.custom_minimum_size = Vector2.ONE*pixels
     samples.add_child(sample)
 elif not "--catch" in OS.get_cmdline_user_args():
  open_collection(mode,"--replace" in OS.get_cmdline_user_args())
  if "--small" in OS.get_cmdline_user_args():
   collection.size = Vector2i(560,420)
   update_collection_layout()
  if "--error" in OS.get_cmdline_user_args():
   handle({"ok":false,"reason":"save_failed"})
 await get_tree().process_frame
 await get_tree().process_frame
 await get_tree().create_timer(.3).timeout
 RenderingServer.force_draw()
 if mode == "tank" and aquarium_view.visible and not Game.state.aquarium.is_empty() and not "--catch" in OS.get_cmdline_user_args() and not "--samples" in OS.get_cmdline_user_args():
  assert(aquarium_view.hit_regions.size() == 6)
  for i in aquarium_view.hit_regions.size():
   for j in range(i+1,aquarium_view.hit_regions.size()):
    assert(not aquarium_view.hit_regions[i].rect.intersects(aquarium_view.hit_regions[j].rect))
  var click := InputEventMouseButton.new()
  click.button_index = MOUSE_BUTTON_LEFT
  click.pressed = true
  click.position = aquarium_view.hit_regions[0].rect.get_center()
  aquarium_view._gui_input(click)
  assert(aquarium_view.selected_id == "qa-0")
  assert(collection_description.text.contains("小丑鱼"))
  await RenderingServer.frame_post_draw
 if "--confirm" in OS.get_cmdline_user_args():
  collection_grid.get_child(0).get_child(0).get_children().back().pressed.emit()
  await get_tree().process_frame
  await get_tree().process_frame
  RenderingServer.force_draw()
 var viewport: Viewport = confirmation if "--confirm" in OS.get_cmdline_user_args() else (get_viewport() if "--catch" in OS.get_cmdline_user_args() or "--samples" in OS.get_cmdline_user_args() else collection)
 if "--ui-review" in OS.get_cmdline_user_args():
  DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/qa/ui"))
  var review_name := "catch" if "--catch" in OS.get_cmdline_user_args() else mode
  for flag in ["small","replace","empty","error","undiscovered","confirm"]:
   if "--"+flag in OS.get_cmdline_user_args():
    review_name += "-"+flag
  assert(viewport.get_texture().get_image().save_png("res://docs/qa/ui/" + review_name + ".png") == OK)
  get_tree().quit()
  return
 viewport.get_texture().get_image().save_png("res://docs/qa/stage3/" + ("samples" if "--samples" in OS.get_cmdline_user_args() else ("catch" if "--catch" in OS.get_cmdline_user_args() else mode)) + ("-small" if "--small" in OS.get_cmdline_user_args() else "") + ("-hidden" if "--undiscovered" in OS.get_cmdline_user_args() else "") + ("-2" if "--page2" in OS.get_cmdline_user_args() else "") + ("-blue" if "--blue" in OS.get_cmdline_user_args() else "") + ".png")
 get_tree().quit()
