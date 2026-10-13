extends Control

var depth := 0.0
var cast := false
var night := false
var working := false
var phase := 0.0
var aquarium_mode := false
var fish_color := Color("b4c8bd")
var elapsed := 0.0

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 resized.connect(queue_redraw)

func _process(delta: float) -> void:
 elapsed += delta
 if elapsed >= 0.1 and visible and is_visible_in_tree() and (working or aquarium_mode):
  phase += elapsed
  elapsed = 0
  queue_redraw()

func fish_shape(center: Vector2, scale_value: float, color: Color, facing: float = 1.0) -> void:
 var body: PackedVector2Array = []
 for i in range(32):
  var angle: float = TAU * i / 32.0
  body.append(center + Vector2(cos(angle)*30.0*scale_value,sin(angle)*15.0*scale_value))
 draw_colored_polygon(body,color)
 draw_polyline(body + PackedVector2Array([body[0]]),Color("7893a0"),1.3,true)
 var tail_x: float = center.x + 28*scale_value*facing
 draw_colored_polygon(PackedVector2Array([Vector2(tail_x,center.y),Vector2(tail_x+15*scale_value*facing,center.y-12*scale_value),Vector2(tail_x+15*scale_value*facing,center.y+12*scale_value)]),color.darkened(0.08))
 draw_circle(center+Vector2(-16*scale_value*facing,-2*scale_value),2.0*scale_value,Color("496775"))
 draw_arc(center+Vector2(-6*scale_value*facing,0),6*scale_value,-0.8,0.8,10,Color("7893a0"),1.0,true)

func _draw() -> void:
 var w: float = size.x
 var h: float = size.y
 if w < 1 or h < 1:
  return
 if aquarium_mode:
  draw_style_box(box(Color("dfedeb")),Rect2(Vector2.ZERO,size))
  draw_line(Vector2(10,h-15),Vector2(w-10,h-15),Color("bdcfc5"),2.0,true)
  fish_shape(Vector2(w*0.5+sin(phase)*12,h*0.5),0.8,fish_color)
  return
 draw_style_box(box(Color("a9c9ce")),Rect2(Vector2.ZERO,size))
 var sky: Color = Color("b0c1d0") if night else Color("e3eae3")
 draw_style_box(box(sky),Rect2(0,0,w,h*0.36))
 var sea_top: float = h*0.35
 for i in range(80):
  var ratio: float = i / 79.0
  var top: Color = Color("9bb8c6") if night else Color("badbd7")
  var bottom: Color = Color("687e9e") if night else Color("849faf")
  draw_rect(Rect2(0,sea_top+(h-sea_top)*ratio,w,(h-sea_top)/79+1),top.lerp(bottom,ratio))
 draw_circle(Vector2(w*0.78,h*0.12),25 if night else 32,Color("edf0da") if night else Color("f3e6c9"))
 for center in [Vector2(w*0.23,h*0.12),Vector2(w*0.58,h*0.23)]:
  paint_ellipse(center,Vector2(45,12),Color("f5f5ec"))
  paint_ellipse(center+Vector2(-5,-7),Vector2(25,18),Color("f5f5ec"))
 paint_ellipse(Vector2(w,h*0.35),Vector2(w*0.2,24),Color("b4c9bc"))
 draw_rect(Rect2(0,sea_top-7,w*0.28,14),Color("d6bda4"))
 draw_line(Vector2(0,sea_top+7),Vector2(w*0.28,sea_top+7),Color("b59e89"),3.0,true)
 draw_rect(Rect2(w*0.2,sea_top+10,10,55),Color("baa38d"))
 draw_line(Vector2(w*0.13,sea_top-10),Vector2(w*0.36,sea_top-65),Color("728e8a"),5,true)
 for i in range(6):
  draw_line(Vector2(w*(0.05+i*0.18),sea_top+15),Vector2(w*(0.11+i*0.18),sea_top+15),Color("e1eee5"),2,true)
 if cast:
  var endpoint := Vector2(w*0.36,sea_top+35+(h-sea_top-85)*depth/200)
  draw_line(Vector2(w*0.36,sea_top-65),endpoint,Color("ecede0"),1.0,true)
  draw_arc(endpoint+Vector2(4,0),5,0,PI,12,Color("e8e5d5"),2,true)
 fish_shape(Vector2(w*0.6+sin(phase*0.4)*18,h*0.58),1.0,Color("dfc2b2"))
 fish_shape(Vector2(w*0.25+sin(phase*0.3)*14,h*0.8),0.65,Color("b6ccc3"),-1.0)
 paint_ellipse(Vector2(w*0.5,h+20),Vector2(w*0.65,65),Color("aec5c3"))
 for i in range(4):
  var base := Vector2(w*(0.1+i*0.24),h-10)
  draw_polyline(PackedVector2Array([base,base+Vector2(-4,-22),base+Vector2(5,-42)]),Color("8faea5"),3,true)

func paint_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
 var points: PackedVector2Array = []
 for i in range(48):
  var angle: float = TAU * i / 48.0
  points.append(center+Vector2(cos(angle)*radius.x,sin(angle)*radius.y))
 draw_colored_polygon(points,color)

func box(color: Color) -> StyleBoxFlat:
 var style := StyleBoxFlat.new()
 style.bg_color = color
 style.set_corner_radius_all(22)
 return style
