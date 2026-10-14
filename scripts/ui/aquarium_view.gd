extends Control
signal fish_selected(catch_id: String)
const Portrait = preload("res://scripts/ui/fish_portrait.gd")
var catches: Array = []
var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/production/collection.animation.json"))
var layers := {}
var phase := 0.0
var hit_regions: Array = []
var selected_id := ""

func _ready() -> void:
 clip_contents = true
 var manifest_path := "res://assets/production/aquarium_manifest.json"
 if FileAccess.file_exists(manifest_path):
  var manifest = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
  for asset in manifest.assets:
   layers[asset.id] = load("res://"+asset.path)
 mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 resized.connect(queue_redraw)

func _process(delta: float) -> void:
 if is_visible_in_tree():
  phase += delta
  queue_redraw()

func _gui_input(event: InputEvent) -> void:
 if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
  for i in range(hit_regions.size()-1,-1,-1):
   if hit_regions[i].rect.has_point(event.position):
    selected_id = hit_regions[i].id
    fish_selected.emit(selected_id)
    accept_event()
    return

func _draw() -> void:
 hit_regions.clear()
 if layers.has("aquarium-background"):
  draw_texture_rect(layers["aquarium-background"],Rect2(Vector2.ZERO,size),false)
  draw_texture_rect(layers["aquarium-water"],Rect2(Vector2.ZERO,size),false)
 else:
  draw_rect(Rect2(Vector2.ZERO,size),Color("dceeea"))
 for i in range(catches.size()):
  var c: Dictionary = catches[i]
  var movement: String = config.species.get(c.species_id,"swim")
  var drift: bool = movement in ["drift","float"]
  var settings: Dictionary = config[movement]
  var t: float = phase*TAU/float(settings.duration)+i*1.31
  if movement == "pulse":
   t += sin(t)*.8
  var width: float = minf(96,minf(size.x*.16,size.y*.36))
  var center := Vector2(size.x*(.19+.30*(i%3)),size.y*(.28+.44*(i/3)))
  center += Vector2(sin(t)*float(settings.horizontal),sin(t*.8)*minf(float(settings.vertical),size.y*.025))
  var rect := Rect2(center-Vector2.ONE*width*.5,Vector2.ONE*width)
  hit_regions.append({"id":c.catch_id,"rect":rect})
  if c.catch_id == selected_id:
   draw_arc(center,width*.48,0,TAU,40,Color("93b6ba"),1.4,true)
  var texture := Portrait.texture_for(c.species_id)
  if texture == null:
   draw_string(ThemeDB.fallback_font,center,"?",HORIZONTAL_ALIGNMENT_CENTER,-1,22,Color("7c989d"))
  else:
   draw_set_transform(center,0,Vector2(1 if drift or cos(t)>=0 else -1,1))
   draw_texture_rect(texture,Rect2(Vector2.ONE*-width*.5,Vector2.ONE*width),false)
   draw_set_transform(Vector2.ZERO)

 if layers.has("aquarium-foreground"):
  draw_texture_rect(layers["aquarium-foreground"],Rect2(Vector2.ZERO,size),false)
