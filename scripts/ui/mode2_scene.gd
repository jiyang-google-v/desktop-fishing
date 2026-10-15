# User-approved v5 presentation. GameService remains the sole owner of catches/saves.
extends Control
const ROOT := 'res://assets/production/mode2-v5/'
var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT+'scene.animation.json'))
var asset_manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT+'asset_manifest.json'))
var layer_order: Array = config.layer_order
var textures := {}
var fish_events: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var ambient_age := 0.0
var spawn_in := 0.0
var action := 'idle'
var action_progress := 1.0
var line_cast := false
var caught_texture: Texture2D
var night := false
var tint := Color.WHITE
var action_age := 0.0
var previous_action := ''
var happy_age := 0.0
func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 for entry in asset_manifest.assets:
  textures[entry.id] = load('res://'+entry.path)
 rng.randomize()
 for i in 5:
  spawn_fish(1 if i%2==0 else -1,i%2,-float(i)*1.1)
 resized.connect(queue_redraw)
func _process(delta: float) -> void:
 if not is_visible_in_tree():
  return
 ambient_age += delta
 if action != previous_action:
  action_age = 0.0
  previous_action = action
 action_age += delta
 happy_age = happy_age+delta if action=='happy' else 0.0
 spawn_in -= delta
 if spawn_in<=0.0:
  if fish_events.size()<int(config.max_swimmers):
   spawn_fish(1 if rng.randf()<.5 else -1,rng.randi_range(0,1),ambient_age)
  spawn_in = rng.randf_range(float(config.spawn_interval[0]),float(config.spawn_interval[1]))
 fish_events = fish_events.filter(func(e): return ambient_age-float(e.start)<float(e.duration))
 queue_redraw()
func spawn_fish(direction: int, depth: int, start: float) -> void:
 fish_events.append({'direction':direction,'depth':depth,'start':start,'duration':rng.randf_range(5,8),'index':rng.randi_range(0,5),'y':rng.randf_range(452,478) if depth==0 else rng.randf_range(485,527),'scale':rng.randf_range(.43,.61) if depth==0 else rng.randf_range(.67,.90),'phase':rng.randf_range(0,TAU)})
func fish_x(event: Dictionary, at: float) -> float:
 var p: float = (at-float(event.start))/float(event.duration)
 return lerpf(42,842,p) if int(event.direction)==1 else lerpf(842,42,p)
func xf(at: Vector2 = Vector2.ZERO, rotation: float = 0.0, zoom: Vector2 = Vector2.ONE) -> void:
 var ratio := size/Vector2(960,640)
 draw_set_transform(at*ratio,rotation,zoom*ratio)
func sprite(id: String, at: Vector2, scale_value: float = 1.0, centered: bool = false) -> void:
 var texture: Texture2D = textures[id]
 var dimensions := texture.get_size()*scale_value
 draw_texture_rect(texture,Rect2(at-(dimensions*.5 if centered else Vector2.ZERO),dimensions),false,tint)
func rig_geometry() -> Dictionary:
 var hand := Vector2(737,395)
 var rotation := 0.0
 var progress: float = clampf(action_progress,0,1)
 if action=='cast':
  rotation = deg_to_rad(-17*sin(progress*PI))
 elif action=='reel':
  rotation = deg_to_rad(-8+29*sin(progress*PI*.65))
 elif action=='happy':
  hand = hand.lerp(Vector2(713,420),smoothstep(0,.4,happy_age))
 var tip: Vector2 = hand+(Vector2(13,17)-Vector2(244,224)).rotated(rotation)
 var short := tip+Vector2(0,23)
 var water := Vector2(469,429+sin(ambient_age*3)*1.2)
 var bobber: Vector2 = water if line_cast else short
 if action=='cast':
  var p: float = smoothstep(.05,.95,progress)
  bobber = short.lerp(water,p)-Vector2(0,95*sin(p*PI))
 elif action=='reel':
  bobber = short
 return {'hand':hand,'tip':tip,'bobber':bobber,'rotation':rotation,'short':not line_cast or action=='reel'}
func draw_swimmers(depth: int) -> void:
 var volume := Rect2(90,438,697,140)
 for event in fish_events:
  if int(event.depth)!=depth:
   continue
  var p: float = (ambient_age-float(event.start))/float(event.duration)
  if p<0 or p>1:
   continue
  var texture: Texture2D = textures['swimmer-'+str(event.index)]
  var dimensions := texture.get_size()*float(event.scale)
  var at := Vector2(fish_x(event,ambient_age),float(event.y)+2.3*sin(ambient_age*1.6+float(event.phase)))
  var full := Rect2(at-dimensions*.5,dimensions)
  var rect := full.intersection(volume)
  if not rect.has_area():
   continue
  var uv0 := (rect.position-full.position)/dimensions
  var uv1 := (rect.end-full.position)/dimensions
  if int(event.direction)<0:
   uv0.x = 1.0-uv0.x
   uv1.x = 1.0-uv1.x
  var color := tint
  color.a *= .85 if depth==0 else 1.0
  draw_polygon(PackedVector2Array([rect.position,Vector2(rect.position.x,rect.end.y),rect.end,Vector2(rect.end.x,rect.position.y)]),PackedColorArray([color]),PackedVector2Array([uv0,Vector2(uv0.x,uv1.y),uv1,Vector2(uv1.x,uv0.y)]),texture)
func plant(index: int, foot: Vector2, scale_value: float, phase: float) -> void:
 var texture: Texture2D = textures['plant-'+str(index)]
 var dimensions := texture.get_size()*scale_value
 var start := foot-Vector2(dimensions.x*.5,dimensions.y)
 for row in 12:
  var a: float = row/12.0
  var b: float = (row+1)/12.0
  var shift_a: float = 7*pow(1-a,2)*sin(ambient_age*TAU/6+phase+(1-a)*.6)*scale_value
  var shift_b: float = 7*pow(1-b,2)*sin(ambient_age*TAU/6+phase+(1-b)*.6)*scale_value
  var points := PackedVector2Array([start+Vector2(shift_a,a*dimensions.y),start+Vector2(shift_b,b*dimensions.y),start+Vector2(shift_b+dimensions.x,b*dimensions.y),start+Vector2(shift_a+dimensions.x,a*dimensions.y)])
  draw_polygon(points,PackedColorArray([tint]),PackedVector2Array([Vector2(0,a),Vector2(0,b),Vector2(1,b),Vector2(1,a)]),texture)
func draw_environment() -> void:
 sprite('environment',Vector2(90,150))
 var texture: Texture2D = textures.environment
 for y in range(260,316,4):
  var displacement: float = 1.3*sin(ambient_age*TAU/6+y*.2)
  draw_texture_rect_region(texture,Rect2(90,150+y+displacement,697,5.5),Rect2(0,y,697,5),tint)
 draw_swimmers(0)
 plant(0,Vector2(172,563),1.0,0)
 plant(1,Vector2(718,560),1.05,1.8)
 draw_swimmers(1)
 plant(0,Vector2(273,581),.65,3.4)
 plant(1,Vector2(647,584),.60,4.6)
 sprite('foreground',Vector2(90,150))
 for i in 4:
  var points := PackedVector2Array()
  for x in range(125,755,12):
   points.append(Vector2(x,426+i*6+1.5*sin(x*.045-ambient_age*TAU/6+i)))
  draw_polyline(points,Color(0.94,1,.98,.17-i*.025),1.5,true)
func draw_actors() -> void:
 var girl := 1 if action=='reel' else (2 if action=='happy' else 0)
 var girl_at := Vector2(774,463 if girl==1 else 458)-Vector2(128,224)
 sprite('girl-'+str(girl),girl_at)
 var cat := 0
 var foot := Vector2(866,428)
 if action=='reel':
  var p: float = clampf(action_progress,0,1)
  cat = 1 if p<.12 or p>.85 else 2
  if cat==2:
   foot.y -= 47*sin(inverse_lerp(.12,.85,p)*PI)
 sprite('cat-'+str(cat),foot-Vector2(64,112))
func _draw() -> void:
 if textures.is_empty() or size.x<=0:
  return
 tint = Color(.92,.95,1) if night else Color.WHITE
 xf()
 draw_environment()
 sprite('pier',Vector2(585,380))
 var rig := rig_geometry()
 draw_line(rig.tip,rig.bobber,Color('6a99b5'),1.5,true)
 xf(rig.hand,rig.rotation)
 sprite('rod',-Vector2(244,224))
 xf()
 draw_actors()
 var bob_scale: float = .7 if rig.short else 1.0
 sprite('bobber',rig.bobber,bob_scale,true)
 if not rig.short and action!='cast':
  draw_arc(rig.bobber+Vector2(0,6),18,0,PI,20,Color(.83,.99,.98,.85),1.5,true)
 if action=='reel' and caught_texture!=null:
  var p: float = clampf(action_progress,0,1)
  var at: Vector2 = pow(1-p,3)*Vector2(469,444)+3*pow(1-p,2)*p*Vector2(457,205)+3*(1-p)*p*p*Vector2(545,151)+pow(p,3)*Vector2(587,211)
  var side: float = 110
  var color := Color(1,1,1,smoothstep(0,.10,p))
  draw_texture_rect(caught_texture,Rect2(at-Vector2.ONE*side*.5,Vector2.ONE*side),false,color)
  if p<.65:
   var alpha: float = 1-p/.65
   var splash_color := Color(1,1,1,alpha)
   var sp: Texture2D = textures.splash
   draw_texture_rect(sp,Rect2(Vector2(469,428)-sp.get_size()*.5,sp.get_size()),false,splash_color)
   for i in 9:
    var dt: float = p*1.5
    var drop := Vector2(469+(i-4)*30*dt,429-(130+i%3*25)*dt+205*dt*dt)
    if drop.y<429:
     draw_circle(drop,2,Color(.5,.85,.94,alpha))
 xf()
