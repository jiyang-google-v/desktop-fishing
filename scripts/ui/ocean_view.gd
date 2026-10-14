extends Control

signal animation_finished
signal splash
const Motion = preload("res://scripts/core/scene_motion.gd")
const BACKGROUND = preload("res://assets/production/scene/ocean-day.png")
const PIER = preload("res://assets/production/scene/pier-cat.png")
const FISHER = preload("res://assets/production/scene/fisher.png")
var motion = Motion.new()
var depth := 0.0
var cast := false
var night := false
var working := false
var aquarium_mode := false
var fish_color := Color("b4c8bd")
var phase := 0.0
var progress_phase := 0.0
var elapsed := 0.0
var splash_age := 10.0
var splash_sent := false
var reel_depth := 0.0

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 clip_contents = true
 resized.connect(queue_redraw)

func is_busy() -> bool:
 return motion.busy()

func play(action: String) -> void:
 if motion.begin(action):
  reel_depth = depth
  splash_sent = false
  queue_redraw()

func skip() -> void:
 if motion.busy():
  motion.skip()
  animation_finished.emit()
  queue_redraw()

func _process(delta: float) -> void:
 if not is_visible_in_tree():
  return
 elapsed += delta
 # Gentle ambience continues when paused; only exploration cues freeze.
 if elapsed < 1.0/30.0:
  return
 phase += elapsed
 if working:
  progress_phase += elapsed
 splash_age += elapsed
 var action: String = motion.active
 motion.advance(elapsed)
 if action == "cast" and not splash_sent and motion.progress >= float(motion.config.animations.cast.splash_at):
  splash_sent = true
  splash_age = 0.0
  splash.emit()
 if not action.is_empty() and not motion.busy():
  if action == "reel":
   splash_age = 0.0
  animation_finished.emit()
 elapsed = 0.0
 queue_redraw()

func fish_shape(center: Vector2, scale_value: float, color: Color, facing: float = 1.0) -> void:
 var body: PackedVector2Array = []
 for i in range(32):
  var angle: float = TAU * i / 32.0
  body.append(center + Vector2(cos(angle)*30.0*scale_value,sin(angle)*15.0*scale_value))
 draw_colored_polygon(body,color)
 var tail_x: float = center.x + 27*scale_value*facing
 draw_colored_polygon(PackedVector2Array([Vector2(tail_x,center.y),Vector2(tail_x+14*scale_value*facing,center.y-11*scale_value),Vector2(tail_x+14*scale_value*facing,center.y+11*scale_value)]),color)
 if aquarium_mode:
  draw_circle(center+Vector2(-16*scale_value*facing,-2*scale_value),2.0*scale_value,Color("496775"))

func _draw() -> void:
 var w: float = size.x
 var h: float = size.y
 if w < 1 or h < 1:
  return
 if aquarium_mode:
  draw_style_box(box(Color("dfedeb")),Rect2(Vector2.ZERO,size))
  fish_shape(Vector2(w*0.5+sin(phase)*12,h*0.5),0.8,fish_color)
  return
 var scale_value: float = minf(w,h)/1000.0
 var surface: float = h*0.28
 draw_texture_rect(BACKGROUND,Rect2(Vector2.ZERO,size),false,Color("a3b1da") if night else Color.WHITE)
 draw_rect(Rect2(Vector2.ZERO,size),Color(1.0,.99,.94,.035 if night else .09))
 # A subtle depth wash does not obscure the artwork.
 draw_rect(Rect2(0,surface,w,h-surface),Color(0.21,0.29,0.48,depth/200.0*0.18))
 # An independent, very soft cloud overlay drifts across the upper sky.
 var cloud_x: float = w*(.48+sin(phase*.025)*.05)
 for cloud_part in [Vector3(-15,0,18),Vector3(0,-5,23),Vector3(20,1,17)]:
  draw_set_transform(Vector2(cloud_x+cloud_part.x*scale_value,h*.09+cloud_part.y*scale_value),0,Vector2(1,.48))
  draw_circle(Vector2.ZERO,cloud_part.z*scale_value,Color(.98,.97,.89,.17 if night else .32))
 draw_set_transform(Vector2.ZERO)
 if night:
  draw_circle(Vector2(w*.66,h*.10),18*scale_value,Color("f8f0cf"))
  for i in range(8):
   draw_circle(Vector2(w*(.48+fmod(i*.073,.45)),h*(.04+fmod(i*.037,.16))),1.6*scale_value,Color("f6f1dc"))
 # Pier: image deck sits at y=.50 of its own transparent canvas.
 var pier_width: float = w*.47
 var pier_height: float = pier_width*.5
 var actor_tint: Color = Color("d5d9ee") if night else Color.WHITE
 draw_texture_rect(PIER,Rect2(Vector2(-w*.018,surface-pier_height*.54),Vector2(pier_width,pier_height)),false,actor_tint)
 var actor_size: float = minf(w,h)*.30
 var actor_pos := Vector2(w*.26,surface-actor_size*.78)
 var breathe: float = sin(phase*TAU/float(motion.config.animations.breathe.duration))*float(motion.config.animations.breathe.amplitude)*scale_value
 actor_pos.y += breathe
 var angle := 0.0
 if motion.active == "cast":
  var keys: Array = motion.config.animations.cast.rod_rotation_degrees
  angle = deg_to_rad(lerpf(float(keys[0]),float(keys[1]),motion.progress*2) if motion.progress < .5 else lerpf(float(keys[1]),float(keys[2]),(motion.progress-.5)*2))
 elif motion.active == "reel":
  var keys: Array = motion.config.animations.reel.rod_rotation_degrees
  angle = deg_to_rad(lerpf(float(keys[0]),float(keys[1]),motion.progress*2) if motion.progress < .5 else lerpf(float(keys[1]),float(keys[2]),(motion.progress-.5)*2))
 # Rod originates at the character's actual hand position, anchored to its layer.
 var hand: Vector2 = actor_pos + Vector2(.70,.65)*actor_size
 var rod_end: Vector2 = hand + Vector2(w*.22,-h*.16).rotated(angle)
 var rod_points := PackedVector2Array()
 for i in range(20):
  var t: float = i/19.0
  rod_points.append(hand.lerp(rod_end,t)+Vector2(0,sin(t*PI)*-5*scale_value))
 draw_polyline(rod_points,Color("758898"),maxf(2,4*scale_value),true)
 draw_polyline(rod_points,Color("d5cbb0"),maxf(1,1.8*scale_value),true)
 draw_texture_rect(FISHER,Rect2(actor_pos,Vector2.ONE*actor_size),false,actor_tint)
 var target := Vector2(w*.59,surface+30*scale_value+(h-surface-90*scale_value)*depth/200.0)
 if cast or motion.busy():
  if motion.active == "cast":
   var t: float = smoothstep(0.0,1.0,motion.progress)
   target = rod_end.lerp(target,t)+Vector2(0,-sin(t*PI)*h*.12)
  elif motion.active == "reel":
   var start := Vector2(w*.59,surface+30*scale_value+(h-surface-90*scale_value)*reel_depth/200.0)
   target = start.lerp(rod_end,smoothstep(0.0,1.0,motion.progress))
  var bobber := Vector2(w*.59,surface+12*scale_value+sin(progress_phase*2)*2*scale_value)
  var line := PackedVector2Array()
  for i in range(30):
   var t: float = i/29.0
   var sway: float = sin(progress_phase*1.5+t*3)*3*scale_value*sin(t*PI)
   var point: Vector2 = rod_end.lerp(target,t)
   if not motion.busy():
    point = rod_end.lerp(bobber,t*2) if t < .5 else bobber.lerp(target,(t-.5)*2)
   line.append(point+Vector2(sway,0))
  draw_polyline(line,Color("fbf6db"),maxf(1,1.6*scale_value),true)
  draw_arc(target+Vector2(4,0)*scale_value,5*scale_value,0,PI*1.45,20,Color("ffedc4"),maxf(1,2*scale_value),true)
  if motion.active != "reel":
   if motion.active != "cast" or motion.progress > .65:
    draw_circle(bobber,7*scale_value,Color("fcf6df"))
    draw_arc(bobber,7*scale_value,PI,TAU,16,Color("e9a6b4"),6*scale_value,true)
 # Water strokes and clouds use quiet procedural movement, not gameplay time.
 for i in range(9):
  var x: float = w*(.05+i*.115)+sin(phase*TAU/float(motion.config.animations.water.duration)+i)*float(motion.config.animations.water.amplitude)*scale_value
  draw_arc(Vector2(x,surface+20*scale_value),20*scale_value,.25,2.8,20,Color(1,.98,.90,.40),1.3,true)
 if cast and motion.active != "cast":
  for i in range(int(motion.config.animations.bubbles.count)):
   var t: float = fmod(progress_phase/float(motion.config.animations.bubbles.duration)+i*.143,1.0)
   var center := Vector2(w*(.52+sin(i*2.0)*.06),lerpf(h*.90,surface+30*scale_value,t))
   draw_arc(center,(2.5+i%3)*scale_value,0,TAU,16,Color(.92,1,1,.38 if working else .12),1.0,true)
  for i in range(3):
   var center := Vector2(w*(.25+i*.24)+sin(progress_phase*.2+i)*12*scale_value,h*(.49+i*.14))
   fish_shape(center,(.38+i*.10)*scale_value,Color(.23,.49,.63,.16),-1 if i%2 else 1)
 if splash_age < 1.0:
  var center := Vector2(w*.59,surface+12*scale_value)
  var radius: float = (8+splash_age*34)*scale_value
  draw_set_transform(center,0,Vector2(1,.35))
  draw_arc(Vector2.ZERO,radius,0,TAU,40,Color(1,1,.96,1-splash_age),2.0,true)
  draw_set_transform(Vector2.ZERO)
  for i in range(5):
   var offset := Vector2((i-2)*8*scale_value,-sin(splash_age*PI)*(18+i%2*8)*scale_value)
   draw_circle(center+offset,2*scale_value,Color(1,1,.96,1-splash_age))
 # Depth ruler is exact UI information over the scene, never baked into art.
 for i in range(5):
  var y: float = surface+42*scale_value+(h-surface-110*scale_value)*i/4.0
  draw_line(Vector2(20*scale_value,y),Vector2(32*scale_value,y),Color("fff8df"),1.6,true)
  draw_string(ThemeDB.fallback_font,Vector2(39*scale_value,y+4*scale_value),"%dm" % (i*50),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("fff8df"))
 draw_style_box(border(),Rect2(Vector2.ZERO,size))

func box(color: Color) -> StyleBoxFlat:
 var style := StyleBoxFlat.new()
 style.bg_color = color
 style.set_corner_radius_all(18)
 return style

func border() -> StyleBoxFlat:
 var style := box(Color.TRANSPARENT)
 style.draw_center = false
 style.border_color = Color("adcddd")
 style.set_border_width_all(2)
 return style
