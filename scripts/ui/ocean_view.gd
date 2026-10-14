extends Control

signal animation_finished
signal splash
const Motion = preload("res://scripts/core/scene_motion.gd")
const BACKGROUND = preload("res://assets/production/scene/ocean-day.png")
const PIER = preload("res://assets/production/scene/pier-clear.png")
const Frames = preload("res://scripts/core/motion_frames.gd")
var frames = Frames.new()
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
var catch_pending := false
var reaction_age := 10.0

func show_catch(value: bool) -> void:
 if value and not catch_pending and not motion.busy():
  reaction_age = 0.0
 catch_pending = value

func actor_clip() -> String:
 if motion.busy():
  return motion.active
 return "happy" if catch_pending and reaction_age < frames.duration("fisher","happy") else "idle"

func actor_clock() -> float:
 if motion.busy():
  return motion.elapsed
 return reaction_age if actor_clip() == "happy" else phase

func cat_clip() -> String:
 if motion.busy():
  return "alert"
 if actor_clip() == "happy":
  return "happy"
 return "blink" if fmod(phase,7.0) < frames.duration("cat","blink") else "idle"

func cat_clock() -> float:
 if motion.busy():
  return motion.progress*frames.duration("cat","alert")
 if actor_clip() == "happy":
  return reaction_age
 return fmod(phase,7.0) if cat_clip() == "blink" else phase

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
  var was_reel: bool = motion.active == "reel"
  motion.skip()
  if was_reel:
   reaction_age = 0.0
  animation_finished.emit()
  queue_redraw()

func _process(delta: float) -> void:
 if not is_visible_in_tree() and not motion.busy():
  return
 elapsed += delta
 # Gentle ambience continues when paused; only exploration cues freeze.
 if elapsed < 1.0/30.0:
  return
 phase += elapsed
 reaction_age += elapsed
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
   reaction_age = 0.0
  animation_finished.emit()
 elapsed = 0.0
 queue_redraw()

func sprite(texture: Texture2D, center: Vector2, canvas: float, tint: Color = Color.WHITE) -> void:
 if texture != null:
  draw_texture_rect(texture,Rect2(center-Vector2.ONE*canvas*.5,Vector2.ONE*canvas),false,tint)

func fishing_line_points(rod_end: Vector2, bobber_anchor: Vector2, hook: Vector2, split_at_bobber: bool, sway_clock: float, scale_value: float, segments: int = 30) -> PackedVector2Array:
 var points := PackedVector2Array()
 var divisions: int = maxi(2,segments)
 for i in range(divisions+1):
  var t: float = float(i)/divisions
  var point: Vector2
  if split_at_bobber and t <= .5:
   var upper_t: float = t*2.0
   point = rod_end.lerp(bobber_anchor,upper_t)
   point.x += sin(sway_clock*1.5+upper_t*3.0)*2.0*scale_value*sin(upper_t*PI)
  elif split_at_bobber:
   var lower_t: float = (t-.5)*2.0
   point = bobber_anchor.lerp(hook,lower_t)
  else:
   point = rod_end.lerp(hook,t)
   point.x += sin(sway_clock*1.5+t*3.0)*2.0*scale_value*sin(t*PI)
  points.append(point)
 return points

func effect(clip: String, center: Vector2, canvas: float, clock: float, opacity: float = 1.0) -> void:
 var anchor := center-Vector2(0,canvas*.32) if clip == "splash" else center
 sprite(frames.texture("fx",clip,clock),anchor,canvas,Color(1,1,1,opacity))

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
 # Independent authored cat and gear layers share a stable deck baseline.
 var cat_size: float = minf(w,h)*.14
 var cat_pos := Vector2(w*.185,surface-6*scale_value)-Vector2(.58,.82)*cat_size
 draw_texture_rect(frames.texture("cat",cat_clip(),cat_clock()),Rect2(cat_pos,Vector2.ONE*cat_size),false,actor_tint)
 var bucket_size: float = minf(w,h)*.10
 var bucket_pos := Vector2(w*.085,surface-5*scale_value)-Vector2(.5,.825)*bucket_size
 draw_texture_rect(frames.gear("bucket"),Rect2(bucket_pos,Vector2.ONE*bucket_size),false,actor_tint)
 var actor_size: float = minf(w,h)*.33
 var actor_pos := Vector2(w*.405,surface-3*scale_value)-Vector2(.55,.71)*actor_size
 var clip: String = actor_clip()
 var clock: float = actor_clock()
 var hand: Vector2 = actor_pos + frames.grip(clip,clock)*actor_size
 var rod_size: float = minf(w,h)*.38
 var rod_pivot: Array = frames.config.gear.rod.pivot
 var rod_tip: Array = frames.config.gear.rod.tip
 var pivot := Vector2(float(rod_pivot[0]),float(rod_pivot[1]))
 var tip := Vector2(float(rod_tip[0]),float(rod_tip[1]))
 var rotation: float = frames.fitted_rod_rotation(clip,clock,hand.y,rod_size,14*scale_value)
 var rod_end: Vector2 = hand+(tip-pivot).rotated(rotation)*rod_size
 draw_set_transform(hand,rotation)
 draw_texture_rect(frames.gear("rod"),Rect2(-pivot*rod_size,Vector2.ONE*rod_size),false,actor_tint)
 draw_set_transform(Vector2.ZERO)
 draw_texture_rect(frames.texture("fisher",clip,clock),Rect2(actor_pos,Vector2.ONE*actor_size),false,actor_tint)
 var bobber_anchor := Vector2(w*.59,surface+12*scale_value+sin(progress_phase*2)*2*scale_value)
 var target := Vector2(w*.59,surface+30*scale_value+(h-surface-90*scale_value)*depth/200.0)
 if cast or motion.busy():
  if motion.active == "cast":
   var splash_at: float = float(motion.config.animations.cast.splash_at)
   if motion.progress < splash_at:
    var cast_t: float = smoothstep(0.0,1.0,motion.progress/maxf(splash_at,.001))
    target = rod_end.lerp(bobber_anchor,cast_t)+Vector2(0,-sin(cast_t*PI)*h*.08)
   else:
    var drop_t: float = smoothstep(0.0,1.0,(motion.progress-splash_at)/maxf(1.0-splash_at,.001))
    target = bobber_anchor.lerp(target,drop_t)
  elif motion.active == "reel":
   var start := Vector2(w*.59,surface+30*scale_value+(h-surface-90*scale_value)*reel_depth/200.0)
   target = start.lerp(rod_end,smoothstep(0.0,1.0,motion.progress))
  var bobber_visible: bool = motion.active != "reel" and (motion.active != "cast" or motion.progress >= float(motion.config.animations.cast.splash_at))
  var line := fishing_line_points(rod_end,bobber_anchor,target,bobber_visible,progress_phase,scale_value)
  draw_polyline(line,Color("fbf6db"),maxf(1,1.6*scale_value),true)
  sprite(frames.gear("hook"),target,26*scale_value,actor_tint)
  effect("glimmer",target,46*scale_value,progress_phase,.60 if working else .22)
  if bobber_visible:
   effect("ripple",bobber_anchor+Vector2(0,3*scale_value),115*scale_value,phase,.72)
   sprite(frames.gear("bobber"),bobber_anchor-Vector2(0,3*scale_value),32*scale_value,actor_tint)
 if cast and motion.active != "cast":
  # Exploration clocks freeze with focus; quiet surface ambience continues.
  for i in range(3):
   var t: float = fmod(progress_phase/float(motion.config.animations.bubbles.duration)+i*.33,1.0)
   var center := Vector2(w*(.52+sin(i*2.0)*.08),lerpf(h*.90,surface+50*scale_value,t))
   effect("bubbles",center,80*scale_value,progress_phase+i*.8,.55 if working else .16)
  for i in range(3):
   var center := Vector2(w*(.25+i*.24)+sin(progress_phase*.2+i)*12*scale_value,h*(.49+i*.14))
   effect("shadow",center,(125+i*15)*scale_value,progress_phase+i,.15 if working else .08)
 if splash_age < frames.duration("fx","splash"):
  effect("splash",Vector2(w*.59,surface+5*scale_value),125*scale_value,splash_age,.85)
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
