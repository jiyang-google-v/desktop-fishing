# Art integration component. Native desktop window switching is intentionally separate.
extends Control
const Frames = preload('res://scripts/core/motion_frames.gd')
const PIER = preload('res://assets/production/scene/reference-pier.png')
const ENVIRONMENT = preload('res://assets/production/scene/reference-floating-environment.png')
var frames = Frames.new()
var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string('res://assets/production/floating.animation.json'))
var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string('res://assets/production/floating_manifest.json'))
var textures := {}
var profile := 'scene'
var action := 'idle'
var action_progress := 0.0
var caught_texture: Texture2D
var age := 0.0
var night := false
var brightness_lift := .10
func _ready() -> void:
 var shader := Shader.new()
 shader.code = "shader_type canvas_item; uniform float brightness_lift = 0.10; void fragment() { COLOR.rgb = mix(COLOR.rgb, vec3(1.0), brightness_lift); }"
 var art_material := ShaderMaterial.new()
 art_material.shader = shader
 art_material.set_shader_parameter("brightness_lift",brightness_lift)
 material = art_material
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
  if config.profiles.scene.fisher.get('flip_h',false):
   grip.x = 1.0-grip.x
  hand = box.position+grip*box.size.x
 var pivot: Vector2 = point(frames.config.gear.rod.pivot)
 var delta: Vector2 = point(frames.config.gear.rod.tip)-pivot
 if profile == 'mini':
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
 # Keep night readable on the desktop without dimming the whole widget.
 var tint := Color(config.night_tint).lerp(Color.WHITE,.72) if night else Color.WHITE
 var rig: Dictionary = rig_geometry()
 var scale_value: float = size.x/600.0
 if profile == 'scene':
  sprite(ENVIRONMENT,Vector2.ZERO,size,false,tint)
  var pier: Array = config.profiles.scene.pier
  var pw: float = float(pier[2])*size.x
  sprite(PIER,Vector2(float(pier[0])*size.x,float(pier[1])*size.y-pw*.205),Vector2(pw,pw*.5),false,tint)
  var cat: Rect2 = actor_box('cat')
  var cat_clip: String = 'alert' if action in ['cast','reel'] else ('happy' if action == 'happy' else 'idle')
  sprite(frames.texture('cat',cat_clip,age),cat.position,cat.size,false,tint)
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
 draw_set_transform(rig.hand,rig.rotation,Vector2(-1 if profile == 'mini' else 1,1))
 draw_texture_rect(frames.gear('rod'),Rect2(-rig.pivot*rod_width,Vector2.ONE*rod_width),false,tint)
 draw_set_transform(Vector2.ZERO)
 if profile == 'scene':
  var actor: Rect2 = actor_box('fisher')
  sprite(frames.texture('fisher',action,age),actor.position,actor.size,false,tint)
  var hook: Vector2 = rig.bobber+Vector2(0,28*scale_value)
  draw_line(rig.bobber,hook,Color('f9f1dc'),maxf(1,scale_value),true)
  sprite(frames.gear('hook'),hook-Vector2.ONE*10*scale_value,Vector2.ONE*20*scale_value,false,tint)
 var bobber_width: float = 20*scale_value if profile == 'scene' else 16*size.x/240.0
 sprite(frames.gear('bobber'),rig.bobber-Vector2.ONE*bobber_width*.5,Vector2.ONE*bobber_width,false,tint)

 # Reveal the saved catch during reeling; no new random draw happens here.
 if action == 'reel' and caught_texture != null:
  var progress: float = smoothstep(.15,.85,action_progress)
  var at: Vector2 = rig.bobber.lerp(rig.tip+Vector2(0,18),progress)
  var width: float = 68.0 if profile == 'scene' else 44.0
  var opacity: float = smoothstep(.05,.25,action_progress)
  sprite(caught_texture,at-Vector2.ONE*width*.5,Vector2.ONE*width,false,Color(1,1,1,opacity))
  for i in 3:
   var bubble: Vector2 = at+Vector2(-16+i*14,24+sin(age*8+i)*5)
   draw_circle(bubble,2.0,Color(.80,.93,.96,opacity*.7))
