extends RefCounted
## Fixed-canvas authored poses; clock selection is separate from gameplay time.
var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/production/motion.animation.json"))
var cache: Dictionary = {}

func sequence(group: String, clip: String) -> Dictionary:
 return config.get("groups",{}).get(group,{}).get("clips",{}).get(clip,{})

func duration(group: String, clip: String) -> float:
 return float(sequence(group,clip).get("duration",1.0))

func frame_index(group: String, clip: String, seconds: float) -> int:
 var item := sequence(group,clip)
 var count: int = item.get("frames",[]).size()
 if count == 0:
  return -1
 var index := int(floor(maxf(seconds,0.0)/maxf(duration(group,clip),.001)*count))
 return index % count if item.get("loop",false) else mini(index,count-1)

func texture(group: String, clip: String, seconds: float) -> Texture2D:
 var index := frame_index(group,clip,seconds)
 if index < 0:
  return null
 var path: String = sequence(group,clip).frames[index]
 if not cache.has(path):
  cache[path] = load("res://" + path)
 return cache[path]

func gear(id: String) -> Texture2D:
 var path: String = config.gear[id].path
 if not cache.has(path):
  cache[path] = load("res://" + path)
 return cache[path]

func grip(clip: String, seconds: float) -> Vector2:
 var item := sequence("fisher",clip)
 var index := frame_index("fisher",clip,seconds)
 var points: Array = item.get("grip",[[.70,.61]])
 var point: Array = points[mini(maxi(index,0),points.size()-1)]
 return Vector2(float(point[0]),float(point[1]))

func rod_rotation(clip: String, seconds: float) -> float:
 var item := sequence("fisher",clip)
 var values: Array = item.get("rod_degrees",[18.0])
 var at: float = maxf(seconds,0.0)/maxf(duration("fisher",clip),.001)*item.get("frames",[]).size()
 var index: int = mini(int(at),values.size()-1)
 var next: int = mini(index+1,values.size()-1)
 return deg_to_rad(lerpf(float(values[index]),float(values[next]),smoothstep(0,1,fmod(at,1.0))))

func fitted_rod_rotation(clip: String, seconds: float, hand_y: float, canvas: float, padding: float) -> float:
 var pivot: Array = config.gear.rod.pivot
 var tip: Array = config.gear.rod.tip
 var shaft := Vector2(float(tip[0])-float(pivot[0]),float(tip[1])-float(pivot[1]))
 var original := shaft.angle()
 var desired := original+rod_rotation(clip,seconds)
 # Keep the full tip inside the sky without changing rod length during a pose.
 var lowest_angle: float = -asin(clampf((hand_y-padding)/maxf(shaft.length()*canvas,.001),0.0,1.0))
 return maxf(desired,lowest_angle)-original
