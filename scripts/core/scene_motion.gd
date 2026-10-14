extends RefCounted
var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/production/scene.animation.json"))
var active := ""
var progress := 1.0
var elapsed := 0.0
func busy() -> bool:
 return not active.is_empty()
func begin(action: String) -> bool:
 if busy() or action not in ["cast","reel"]:
  return false
 active = action
 progress = 0.0
 elapsed = 0.0
 return true
func advance(delta: float) -> void:
 if not busy():
  return
 elapsed += maxf(delta,0.0)
 progress = clampf(elapsed / float(config.animations[active].duration),0.0,1.0)
 if progress >= 1:
  active = ""
func skip() -> void:
 active = ""
 progress = 1.0
