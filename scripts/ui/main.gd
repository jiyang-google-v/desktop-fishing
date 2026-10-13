extends Control

const Ocean = preload("res://scripts/ui/ocean_view.gd")
const RARITY := {"common":"常见","uncommon":"少见","rare":"稀有","legendary":"传说"}
const STATUS := {
 "ready":["准备出发","放钩后切换到其他工作窗口，鱼钩会随专注慢慢下潜。"],
 "foreground":["暂歇片刻","游戏在前台，进度已保留。切到其他窗口后继续。"],
 "working":["正在探索深海","安心工作，休息时回来收杆，揭晓这次相遇。"],
 "idle":["等待你回来","键鼠空闲超过 10 分钟，已暂停并保留深度。"],
 "locked":["海面暂时安静","锁屏、断开会话或安全桌面期间暂停计时。"],
 "unsupported":["专注检测暂不可用","检测失败时保守暂停；专注计时仅支持 Windows。"],
 "pending":["遇见一位新朋友","收进鱼缸或放生后，即可再次放钩。"],
 "max_depth":["抵达 200 米","已经到达最深处，可以收杆看看。"],
 "blocked":["存档需要处理","为保护已有数据，已暂停游戏操作。"]
}
var ocean
var status_title: Label
var status_text: Label
var depth_text: Label
var time_text: Label
var scene_text: Label
var progress: ProgressBar
var cast_button: Button
var reel_button: Button
var book_button: Button
var tank_button: Button
var catch_box: VBoxContainer
var notice: Label
var collection: Window
var collection_title: Label
var collection_description: Label
var collection_grid: GridContainer
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
 get_window().min_size = Vector2i(940,700)
 get_window().title = "桌面钓鱼 · Godot 试玩版"
 theme = make_theme()
 build_ui()
 Game.changed.connect(refresh)
 refresh()
 if "--export-smoke" in OS.get_cmdline_user_args():
  var valid: bool = Game.model.roster.size() == 14 and FileAccess.file_exists("res://platform/windows/focus-worker.ps1")
  get_tree().quit(0 if valid else 1)
 if "--ui-smoke" in OS.get_cmdline_user_args():
  call_deferred("ui_smoke")

func make_theme() -> Theme:
 var t := Theme.new()
 var font := SystemFont.new()
 font.font_names = PackedStringArray(["Microsoft YaHei","Noto Sans CJK SC","WenQuanYi Micro Hei","sans-serif"])
 t.default_font = font
 t.default_font_size = 14
 t.set_color("font_color","Label",Color("486575"))
 for type in ["Button","Window","ConfirmationDialog"]:
  t.set_color("font_color",type,Color("486575"))
 t.set_stylebox("normal","Button",style(Color("edf4ef"),12))
 t.set_stylebox("hover","Button",style(Color("dceae3"),12))
 t.set_stylebox("pressed","Button",style(Color("c9ded5"),12))
 t.set_stylebox("disabled","Button",style(Color("e7eae4"),12))
 t.set_color("font_disabled_color","Button",Color("a4b4b3"))
 t.set_stylebox("panel","PanelContainer",style(Color("fafaf4"),22))
 t.set_stylebox("background","ProgressBar",style(Color("d6e3db"),5))
 t.set_stylebox("fill","ProgressBar",style(Color("8fb4a9"),5))
 return t

func style(color: Color, radius: int) -> StyleBoxFlat:
 var result := StyleBoxFlat.new()
 result.bg_color = color
 result.set_corner_radius_all(radius)
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
 margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for edge in ["left","right","top","bottom"]:
  margin.add_theme_constant_override("margin_"+edge,24)
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
 title_box.add_child(label("DESKTOP FISHING  /  GODOT",10,true))
 title_box.add_child(label("一小片属于你的海",24))
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
 var ocean_margin := MarginContainer.new()
 ocean_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 ocean_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
 for edge in ["left","right","top","bottom"]:
  ocean_margin.add_theme_constant_override("margin_"+edge,20)
 ocean.add_child(ocean_margin)
 var overlay := VBoxContainer.new()
 overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
 ocean_margin.add_child(overlay)
 scene_text = label("白昼的海",14)
 overlay.add_child(scene_text)
 depth_text = label("0.0 米",32)
 overlay.add_child(depth_text)
 var spacer := Control.new()
 spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
 overlay.add_child(spacer)
 overlay.add_child(label("功能示意场景 · 正式 V2.6 美术待接入",11,true))
 var side_panel := PanelContainer.new()
 side_panel.custom_minimum_size.x = 310
 body.add_child(side_panel)
 var side := VBoxContainer.new()
 side.add_theme_constant_override("separation",14)
 side_panel.add_child(side)
 side.add_child(label("慢慢工作，轻轻收获",11,true))
 status_title = label("准备出发",23)
 side.add_child(status_title)
 status_text = paragraph("",side)
 status_text.custom_minimum_size.y = 58
 var card := PanelContainer.new()
 card.add_theme_stylebox_override("panel",style(Color("e9f0e9"),14))
 side.add_child(card)
 var time_box := VBoxContainer.new()
 time_box.add_theme_constant_override("separation",8)
 card.add_child(time_box)
 time_box.add_child(label("本次有效专注",12,true))
 time_text = label("00:00",32)
 time_box.add_child(time_text)
 progress = ProgressBar.new()
 progress.max_value = 200
 progress.show_percentage = false
 progress.custom_minimum_size.y = 8
 time_box.add_child(progress)
 time_box.add_child(label("每分钟 4 米 · 最深 200 米",11,true))
 var actions := HBoxContainer.new()
 actions.add_theme_constant_override("separation",8)
 side.add_child(actions)
 cast_button = button("放下鱼钩",actions,func(): handle(Game.cast_line()))
 reel_button = button("收杆看看",actions,func(): handle(Game.reel_line()))
 cast_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 reel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 cast_button.add_theme_stylebox_override("normal",style(Color("d1e5da"),12))
 reel_button.add_theme_stylebox_override("normal",style(Color("efdfd2"),12))
 catch_box = VBoxContainer.new()
 catch_box.add_theme_constant_override("separation",8)
 side.add_child(catch_box)
 notice = paragraph("",side,12)
 notice.add_theme_color_override("font_color",Color("9b745c"))
 var side_spacer := Control.new()
 side_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
 side.add_child(side_spacer)
 paragraph("游戏前台暂停。后台且最近 10 分钟有键鼠操作时下潜。锁屏、休眠与退出期间不累计。",side,11)
 var footer := HBoxContainer.new()
 root.add_child(footer)
 var version := label("桌面钓鱼 · 0.3.0 Godot 功能试玩版",11,true)
 version.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 footer.add_child(version)
 footer.add_child(label("不记录按键内容或窗口标题",11,true))
 build_dialogs()

func build_dialogs() -> void:
 collection = Window.new()
 collection.title = "收藏"
 collection.theme = theme
 collection.size = Vector2i(750,520)
 collection.min_size = Vector2i(720,420)
 collection.transient = true
 collection.exclusive = true
 collection.close_requested.connect(func(): collection.hide())
 collection.window_input.connect(func(event):
  if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
   collection.hide())
 add_child(collection)
 var margin := MarginContainer.new()
 margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for edge in ["left","right","top","bottom"]:
  margin.add_theme_constant_override("margin_"+edge,20)
 collection.add_child(margin)
 var box := VBoxContainer.new()
 box.add_theme_constant_override("separation",12)
 margin.add_child(box)
 var header := HBoxContainer.new()
 box.add_child(header)
 collection_title = label("",22)
 collection_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 header.add_child(collection_title)
 button("关闭",header,func(): collection.hide())
 collection_description = paragraph("",box)
 var scroll := ScrollContainer.new()
 scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 box.add_child(scroll)
 collection_grid = GridContainer.new()
 collection_grid.columns = 3
 collection_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 collection_grid.add_theme_constant_override("h_separation",12)
 collection_grid.add_theme_constant_override("v_separation",12)
 scroll.add_child(collection_grid)
 confirmation = ConfirmationDialog.new()
 confirmation.title = "确认操作"
 confirmation.theme = theme
 confirmation.ok_button_text = "确认"
 confirmation.cancel_button_text = "取消"
 confirmation.min_size = Vector2i(420,180)
 confirmation.transient = true
 confirmation.exclusive = true
 add_child(confirmation)
 confirmation.confirmed.connect(func():
  var action: Callable = confirm_action
  confirm_action = Callable()
  if action.is_valid():
   action.call())
 confirmation.canceled.connect(func(): confirm_action = Callable())

func handle(result: Dictionary) -> void:
 if not result.ok:
  var messages := {"full":"鱼缸已满，请选择替换。","save_failed":"保存失败，操作未完成。","blocked":"存档不可用，已暂停操作。","pending":"请先安置本次鱼获。"}
  notice.text = messages.get(result.get("reason",""),"操作未完成，请重试。")

func ask(text: String, action: Callable) -> void:
 confirm_action = action
 var parent: Node = collection if collection.visible else self
 if confirmation.get_parent() != parent:
  confirmation.reparent(parent)
 confirmation.dialog_text = text
 confirmation.popup_centered()

func refresh() -> void:
 if status_title == null:
  return
 var s: Dictionary = Game.state
 var reason: String = Game.pause_reason()
 var status: Array = STATUS.get(reason,STATUS.ready)
 status_title.text = status[0]
 status_text.text = status[1]
 var depth: float = Game.model.depth_for(s.focus_seconds)
 depth_text.text = "%.1f 米" % depth
 time_text.text = "%02d:%02d" % [int(s.focus_seconds)/60,int(s.focus_seconds)%60]
 progress.value = depth
 var hour: int = Time.get_datetime_dict_from_system().hour
 ocean.depth = depth
 ocean.cast = s.cast
 ocean.night = hour < 6 or hour >= 18
 ocean.working = reason == "working"
 ocean.queue_redraw()
 var layer := "表层" if depth < 30 else ("浅海" if depth < 100 else "深水")
 scene_text.text = ("夜晚的海" if ocean.night else "白昼的海") + " · " + layer
 cast_button.disabled = Game.blocked or s.cast or not s.pending_catch.is_empty()
 reel_button.disabled = Game.blocked or not s.cast
 book_button.text = "图鉴 %d / %d" % [s.encyclopedia.size(),Game.model.roster.size()]
 tank_button.text = "鱼缸 %d / 6" % s.aquarium.size()
 notice.text = Game.warning
 notice.visible = not notice.text.is_empty()
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

func render_catch() -> void:
 clear_children(catch_box)
 var c: Dictionary = Game.state.pending_catch
 if c.is_empty():
  catch_box.add_child(label("下一次相遇",13))
  paragraph("鱼获由收杆时的深度和昼夜决定。发现过的鱼会留在图鉴中。",catch_box,12)
  return
 var f: Dictionary = Game.model.species(c.species_id)
 catch_box.add_child(label("本次鱼获 · " + RARITY.get(f.rarity,f.rarity),11,true))
 catch_box.add_child(label(f.name,22))
 catch_box.add_child(label("%.1f cm · %.1f m" % [c.length_cm,c.depth],13,true))
 var row := HBoxContainer.new()
 row.add_theme_constant_override("separation",8)
 catch_box.add_child(row)
 var keep := button("选择替换" if Game.state.aquarium.size() >= 6 else "收进鱼缸",row,func():
  if Game.state.aquarium.size() >= 6:
   open_collection("tank",true)
  else:
   handle(Game.settle("keep")))
 var release := button("放生",row,func(): ask("放生这次鱼获？图鉴次数和体长纪录会保留。",func(): handle(Game.settle("release"))))
 keep.disabled = Game.blocked
 release.disabled = Game.blocked

func open_collection(mode: String, replace: bool = false) -> void:
 panel_mode = mode
 replacing = replace
 panel_signature = ""
 render_collection()
 collection.popup_centered()

func card() -> VBoxContainer:
 var panel := PanelContainer.new()
 panel.custom_minimum_size.x = 205
 panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 panel.add_theme_stylebox_override("panel",style(Color("e7efea"),14))
 collection_grid.add_child(panel)
 var box := VBoxContainer.new()
 box.add_theme_constant_override("separation",8)
 panel.add_child(box)
 return box

func render_collection() -> void:
 var s: Dictionary = Game.state
 var signature: String = JSON.stringify([panel_mode,replacing,s.encyclopedia,s.aquarium,s.pending_catch,Game.blocked])
 if signature == panel_signature:
  return
 panel_signature = signature
 clear_children(collection_grid)
 collection_title.text = "鱼类图鉴" if panel_mode == "book" else "精选鱼缸"
 collection_description.text = "每次相遇都留下纪录。" if panel_mode == "book" else ("选择要替换的鱼。取消会保留原鱼和本次鱼获。" if replacing else "最多展示 6 条精选鱼。放生不删除图鉴纪录。")
 if panel_mode == "book":
  for f in Game.model.roster:
   var box: VBoxContainer = card()
   var record: Dictionary = s.encyclopedia.get(f.id,{})
   box.add_child(label(f.name if not record.is_empty() else "尚未发现",16))
   if record.is_empty():
    paragraph("等待一次惊喜相遇\n???",box,12)
   else:
    paragraph("%s · 捕获 %d 次\n最大体长 %.1f cm" % [RARITY.get(f.rarity,f.rarity),record.count,record.record_cm],box,12)
  return
 if s.aquarium.is_empty():
  paragraph("鱼缸还很安静。收杆后选择收进鱼缸，邀请第一位朋友。",card())
 for c in s.aquarium:
  var box: VBoxContainer = card()
  var mini = Ocean.new()
  mini.aquarium_mode = true
  mini.custom_minimum_size = Vector2(160,76)
  box.add_child(mini)
  var f: Dictionary = Game.model.species(c.species_id)
  box.add_child(label(f.name,16))
  box.add_child(label("%.1f cm" % c.length_cm,12,true))
  var catch_id: String = c.catch_id
  var chosen = button("替换这条鱼" if replacing else "放生",box,func():
   if replacing:
    ask("放生 %s（%.1f cm），让本次鱼获住进来？" % [f.name,c.length_cm],func():
     var result: Dictionary = Game.settle("replace",catch_id)
     handle(result)
     if result.ok:
      replacing = false
      collection.hide())
   else:
    ask("放生 %s（%.1f cm）？图鉴纪录会保留。" % [f.name,c.length_cm],func(): handle(Game.remove_from_tank(catch_id))))
  chosen.disabled = Game.blocked

func ui_smoke() -> void:
 # Isolated in-memory UI check; no save writes or Windows sampling.
 Game.state = Game.model.fresh_state()
 refresh()
 assert(not cast_button.disabled)
 assert(reel_button.disabled)
 assert(Game.model.cast_line(Game.state).ok)
 refresh()
 assert(cast_button.disabled and not reel_button.disabled)
 assert(Game.model.reel_line(Game.state,12,Game.rng).ok)
 refresh()
 assert(cast_button.disabled and reel_button.disabled)
 assert(Game.model.settle(Game.state,"keep").ok)
 open_collection("tank")
 assert(collection_grid.get_child_count() == 1)
 collection.hide()
 open_collection("book")
 assert(collection_grid.get_child_count() == 14)
 collection.hide()
 var test_path: String = "user://ui-test-%s.json" % Game.model.new_id()
 Game.save_path = test_path
 assert(Game.model.cast_line(Game.state).ok)
 assert(Game.model.reel_line(Game.state,12,Game.rng).ok)
 for i in range(5):
  var existing: Dictionary = Game.state.pending_catch.duplicate(true)
  existing.catch_id = "ui-old-%d" % i
  Game.state.aquarium.append(existing)
 refresh()
 open_collection("tank",true)
 var original: Dictionary = Game.state.duplicate(true)
 var target_panel: Node = collection_grid.get_child(2)
 var target_button: Button = target_panel.get_child(0).get_children().back()
 target_button.pressed.emit()
 assert(confirmation.visible)
 confirmation.hide()
 confirmation.canceled.emit()
 assert(Game.state == original)
 target_button.pressed.emit()
 confirmation.hide()
 confirmation.confirmed.emit()
 assert(Game.state.pending_catch.is_empty())
 assert(Game.state.aquarium.size() == 6)
 assert(not collection.visible)
 for suffix in ["", ".bak", ".tmp"]:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path + suffix))
 print("Godot UI smoke: cast, reel, keep, book, full-tank cancel and replacement passed")
 get_tree().quit()
