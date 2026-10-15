extends Window
signal dismissed
var main
var panel: PanelContainer
var title_label: Label
var detail: Label
var badges: Label
var fish
var keep_button: Button
var release_button: Button
var later_button: Button
var current_id := ''
var card_root: Control
var back_cover: PanelContainer
var reveal_age := 2.0
var is_revealed := true
var reveal_sound_played := false
var introductions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string('res://data/fish-introductions.json'))
var reveal_count := 0
var reveal_tween: Tween
func _ready() -> void:
 visible = false
 force_native = true
 borderless = true
 unresizable = true
 transparent = true
 transparent_bg = true
 transient = true
 unfocusable = false
 size = Vector2i(280,410)
 content_scale_size = size
 panel = PanelContainer.new()
 panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var skin: StyleBoxFlat = main.style(Color('fffbee'),14)
 skin.set_content_margin_all(12)
 panel.add_theme_stylebox_override('panel',skin)
 card_root = Control.new()
 card_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(card_root)
 card_root.add_child(panel)
 var body := VBoxContainer.new()
 body.add_theme_constant_override('separation',6)
 panel.add_child(body)
 title_label = main.label('鱼获揭晓',16)
 body.add_child(title_label)
 fish = main.Portrait.new()
 fish.custom_minimum_size = Vector2(110,110)
 fish.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 body.add_child(fish)
 detail = main.label('',12,true)
 detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 body.add_child(detail)
 badges = main.label('',11,true)
 body.add_child(badges)
 var actions := HBoxContainer.new()
 body.add_child(actions)
 keep_button = main.button('收进鱼缸',actions,func(): settle.call_deferred('keep'))
 release_button = main.button('放生',actions,func(): confirm_release.call_deferred())
 later_button = main.button('稍后安置',body,func():
  hide()
  dismissed.emit())
 back_cover = PanelContainer.new()
 back_cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var back_skin: StyleBoxFlat = main.style(Color('e0efeb'),18)
 back_skin.border_color = Color('b6cfc8')
 back_skin.set_border_width_all(2)
 back_cover.add_theme_stylebox_override('panel',back_skin)
 var back_body := VBoxContainer.new()
 back_body.alignment = BoxContainer.ALIGNMENT_CENTER
 back_cover.add_child(back_body)
 for entry in [['海里的礼物',18],['?',64],['会遇见谁呢？',17],['点击可跳过揭晓',11]]:
  var line: Label = main.label(entry[0],entry[1])
  line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  back_body.add_child(line)
 card_root.add_child(back_cover)
 back_cover.gui_input.connect(func(event):
  if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
   reveal_age = 1.6)
 close_requested.connect(func():
  hide()
  dismissed.emit())
func present(game) -> void:
 var caught: Dictionary = game.state.pending_catch
 var id: String = str(caught.get('catch_id',''))
 if id.is_empty():
  hide()
  return
 var species: Dictionary = game.model.species(caught.species_id)
 title_label.text = species.name+' · '+str(main.RARITY.get(species.rarity,species.rarity))
 fish.species_id = caught.species_id
 fish.queue_redraw()
 detail.text = '%.1f cm' % caught.length_cm
 var habitat: Dictionary = introductions
 if habitat.has(str(caught.species_id)):
  var intro: Dictionary = habitat[str(caught.species_id)]
  detail.text += '\n'+str(intro.habitat)+'\n'+str(intro.description)
 if caught.has('duration_minutes'):
  detail.text += ' · 专注%d分钟' % int(caught.duration_minutes)
 var flags: Array[String] = []
 if caught.get('first_discovery',false):
  flags.append('首次发现')
 if caught.get('new_record',false):
  flags.append('新纪录')
 badges.text = ' · '.join(flags) if not flags.is_empty() else '图鉴已记录'
 keep_button.text = '选择替换' if game.state.aquarium.size() >= 6 else '收进鱼缸'
 keep_button.disabled = game.blocked or not is_revealed
 release_button.disabled = game.blocked or not is_revealed
 if id == current_id:
  return
 current_id = id
 reveal_count += 1
 reveal_age = 0.0
 is_revealed = false
 reveal_sound_played = false
 fish.scale = Vector2.ONE
 fish.modulate.a = 1.0
 update_reveal()
func reveal_geometry(at: float) -> Dictionary:
 var entry: float = smoothstep(0,.24,at)
 var flip: float = smoothstep(.85,1.38,at)
 var width: float = maxf(.02,absf(cos(flip*PI)))
 var scale_value: float = lerpf(.9,1.0,entry)
 var anticipation: float = smoothstep(.24,.45,at)*(1-smoothstep(.60,.80,at))
 return {'scale':Vector2(width,1)*scale_value,'offset':Vector2(sin(at*22)*1.5*anticipation,0),'front':at>=1.115}
func _process(delta: float) -> void:
 if not visible:
  return
 reveal_age += delta
 update_reveal()
func update_reveal() -> void:
 if not is_instance_valid(card_root):
  return
 var geometry := reveal_geometry(reveal_age)
 card_root.pivot_offset = Vector2(size)*.5
 card_root.scale = geometry.scale
 card_root.position = geometry.offset
 panel.visible = geometry.front
 back_cover.visible = not geometry.front
 is_revealed = reveal_age>=1.38
 var game = main.get_node('/root/Game')
 keep_button.disabled = not is_revealed or game.blocked
 release_button.disabled = not is_revealed or game.blocked
 later_button.disabled = not is_revealed
 if is_revealed and not reveal_sound_played:
  reveal_sound_played = true
  main.scene_audio.play('reel')

func settle(action: String) -> void:
 var game = main.get_node('/root/Game')
 if game.state.pending_catch.is_empty() or str(game.state.pending_catch.catch_id) != current_id:
  return
 if action == 'keep' and game.state.aquarium.size() >= 6:
  hide()
  main.open_collection('tank',true)
  return
 var result: Dictionary = main.settle_catch(action)
 if result.ok:
  hide()
func confirm_release() -> void:
 hide()
 main.ask('放生这次鱼获？图鉴次数和体长纪录会保留。',func(): settle('release'),'确认放生')
