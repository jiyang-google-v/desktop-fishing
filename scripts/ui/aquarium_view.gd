extends Control
signal fish_selected(catch_id: String)
const Portrait = preload("res://scripts/ui/fish_portrait.gd")
var catches: Array = []
var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/production/collection.animation.json"))
var phase := 0.0
var hit_regions: Array = []
var selected_id := ""

func _ready() -> void:
 clip_contents = true
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
 draw_rect(Rect2(Vector2.ZERO,size),Color("dceeea"))
 draw_rect(Rect2(0,size.y*.7,size.x,size.y*.3),Color("e9ead8"))
 for i in range(9):
  var x: float = size.x*(i+.5)/9
  draw_arc(Vector2(x,18),18,.2,2.9,16,Color("f7f9ee"),2,true)
 for i in range(7):
  var x: float = size.x*(i+.5)/7
  draw_line(Vector2(x,size.y),Vector2(x+sin(phase*.3+i)*5,size.y-25-i%3*8),Color("b2cfbf"),4,true)
 for i in range(catches.size()):
  var c: Dictionary = catches[i]
  var drift: bool = c.species_id == "fish_004_seahorse"
  var settings: Dictionary = config.drift if drift else config.swim
  var t: float = phase*TAU/float(settings.duration)+i*1.31
  var width: float = minf(96,size.x*.16)
  var center := Vector2(size.x*(.19+.30*(i%3)),size.y*(.30+.34*(i/3)))
  center += Vector2(sin(t)*float(settings.horizontal),sin(t*.8)*float(settings.vertical))
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
