# Art integration component. Native desktop window switching is intentionally separate.
extends Control
const Frames = preload('res://scripts/core/motion_frames.gd')
const PIER = preload('res://assets/production/scene/pier-clear.png')
var frames = Frames.new()
var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string('res://assets/production/floating.animation.json'))
var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string('res://assets/production/floating_manifest.json'))
var textures := {}
var profile := 'scene'
var action := 'idle'
var age := 0.0
var night := false
func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 clip_contents = true
 for entry in manifest.assets:
  textures[entry.id] = load('res://'+entry.path)
 resized.connect(queue_redraw)
func _process(delta: float) -> void:
 if is_visible_in_tree():
  age += delta
  queue_redraw()
func point(value: Array) -> Vector2:
 return Vector2(float(value[0]),float(value[1]))
func position_from(value: Array) -> Vector2:
 return point(value)*size
func sprite(texture: Texture2D, at: Vector2, canvas_size: Vector2, flip: bool = false, tint: Color = Color.WHITE) -> void:
 draw_set_transform(at+Vector2(canvas_size.x if flip else 0.0,0),0,Vector2(-1 if flip else 1,1))
 draw_texture_rect(texture,Rect2(Vector2.ZERO,canvas_size),false,tint)
 draw_set_transform(Vector2.ZERO)
func actor_box(group: String) -> Rect2:
 var spec: Dictionary = config.profiles.scene[group]
 var width: float = size.x*float(spec.canvas_width)
 var pivot: Vector2 = point(frames.config.groups[group].pivot)
 if spec.get('flip_h',false):
  pivot.x = 1.0-pivot.x
 return Rect2(position_from(spec.anchor)-pivot*width,Vector2.ONE*width)
func rig_geometry() -> Dictionary:
 var spec: Dictionary = config.profiles[profile].rod
 var canvas_width: float = size.x*float(spec.canvas_width)
 var hand: Vector2
 if profile == 'mini':
  hand = position_from(spec.hand_anchor)
 else:
  var box: Rect2 = actor_box('fisher')
  var grip: Vector2 = frames.grip(action,age)
  grip.x = 1.0-grip.x
  hand = box.position+grip*box.size.x
 var pivot: Vector2 = point(frames.config.gear.rod.pivot)
 var delta: Vector2 = point(frames.config.gear.rod.tip)-pivot
 delta.x = -delta.x
 var rotation: float = deg_to_rad(float(spec.rotation_degrees))
 var tip: Vector2 = hand+(delta*canvas_width).rotated(rotation)
 return {'hand':hand,'tip':tip,'bobber':Vector2(tip.x,size.y*float(config.profiles[profile].bobber_y)),'canvas_width':canvas_width,'rotation':rotation,'pivot':pivot}
func draw_layer(id: String, tint: Color) -> void:
 var r: Array = config.profiles.scene.layers[id]
 var at := Vector2(float(r[0])*size.x,float(r[1])*size.y)
 if id.begins_with('cloud'):
  at.x += sin(age*TAU/float(config.ambient.cloud_drift.duration))*float(config.ambient.cloud_drift.amplitude_px)
 var color := tint
 if id == 'corner-water':
  var limits: Array = config.ambient.water_breathe.alpha_range
  color.a = lerpf(float(limits[0]),float(limits[1]),(sin(age*TAU/float(config.ambient.water_breathe.duration))+1.0)*.5)
 sprite(textures[id],at,Vector2(float(r[2])*size.x,float(r[3])*size.y),false,color)
func _draw() -> void:
 if textures.is_empty() or size.x <= 0 or size.y <= 0:
  return
 var tint := Color(config.night_tint) if night else Color.WHITE
 var rig: Dictionary = rig_geometry()
 var scale_value: float = size.x/600.0
 if profile == 'scene':
  for id in ['cloud-large','cloud-small','distant-island','corner-water']:
   draw_layer(id,tint)
  var pier: Array = config.profiles.scene.pier
  var pw: float = float(pier[2])*size.x
  sprite(PIER,Vector2(float(pier[0])*size.x,float(pier[1])*size.y-pw*.25),Vector2(pw,pw*.5),true,tint)
  var cat: Rect2 = actor_box('cat')
  var cat_clip: String = 'alert' if action in ['cast','reel'] else ('happy' if action == 'happy' else 'idle')
  sprite(frames.texture('cat',cat_clip,age),cat.position,cat.size,true,tint)
  var bucket: Dictionary = config.profiles.scene.bucket
  var width: float = float(bucket.canvas_width)*size.x
  sprite(frames.gear('bucket'),position_from(bucket.anchor)-Vector2(.5,.825)*width,Vector2.ONE*width,false,tint)
 else:
  var width: float = size.x*float(config.profiles.mini.water_canvas_width)
  var pulse: Array = config.ambient.mini_ripple.scale_range
  width *= lerpf(float(pulse[0]),float(pulse[1]),(sin(age*TAU/float(config.ambient.mini_ripple.duration))+1.0)*.5)
  sprite(textures['mini-water'],rig.bobber-Vector2(.5,.58)*width*Vector2(1,.5),Vector2(width,width*.5),false,tint)
 # Line is geometry, never baked into art. Both profiles share the same rig anchor.
 draw_line(rig.tip,rig.bobber,Color('f9f1dc'),maxf(1,1.4*scale_value),true)
 var rod_width: float = rig.canvas_width
 draw_set_transform(rig.hand,rig.rotation,Vector2(-1,1))
 draw_texture_rect(frames.gear('rod'),Rect2(-rig.pivot*rod_width,Vector2.ONE*rod_width),false,tint)
 draw_set_transform(Vector2.ZERO)
 if profile == 'scene':
  var actor: Rect2 = actor_box('fisher')
  sprite(frames.texture('fisher',action,age),actor.position,actor.size,true,tint)
  var hook: Vector2 = rig.bobber+Vector2(0,28*scale_value)
  draw_line(rig.bobber,hook,Color('f9f1dc'),maxf(1,scale_value),true)
  sprite(frames.gear('hook'),hook-Vector2.ONE*10*scale_value,Vector2.ONE*20*scale_value,false,tint)
  draw_layer('shore-rocks',tint)
 var bobber_width: float = 20*scale_value if profile == 'scene' else 16*size.x/240.0
 sprite(frames.gear('bobber'),rig.bobber-Vector2.ONE*bobber_width*.5,Vector2.ONE*bobber_width,false,tint)
