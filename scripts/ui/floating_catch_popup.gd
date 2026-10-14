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
 size = Vector2i(260,320)
 content_scale_size = size
 panel = PanelContainer.new()
 panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var skin: StyleBoxFlat = main.style(Color('fffbee'),14)
 skin.set_content_margin_all(12)
 panel.add_theme_stylebox_override('panel',skin)
 add_child(panel)
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
 if caught.has('duration_minutes'):
  detail.text += ' · 专注%d分钟' % int(caught.duration_minutes)
 var flags: Array[String] = []
 if caught.get('first_discovery',false):
  flags.append('首次发现')
 if caught.get('new_record',false):
  flags.append('新纪录')
 badges.text = ' · '.join(flags) if not flags.is_empty() else '图鉴已记录'
 keep_button.text = '选择替换' if game.state.aquarium.size() >= 6 else '收进鱼缸'
 keep_button.disabled = game.blocked
 release_button.disabled = game.blocked
 if id == current_id:
  return
 current_id = id
 reveal_count += 1
 if reveal_tween != null:
  reveal_tween.kill()
 fish.scale = Vector2(.8,.8)
 fish.modulate.a = 0.0
 reveal_tween = create_tween().set_parallel(true)
 reveal_tween.tween_property(fish,'scale',Vector2.ONE,.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
 reveal_tween.tween_property(fish,'modulate:a',1.0,.25)
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
