extends RefCounted
# Shared cubic leap: fast emergence, a soft apex, then stable card handoff.
static func fish_position(progress: float, water: Vector2, landing: Vector2, lift: float) -> Vector2:
 var p := clampf(progress,0,1)
 var first := water+Vector2(-lift*.05,-lift)
 var second := landing+Vector2(-lift*.18,-lift*.25)
 return pow(1-p,3)*water+3*pow(1-p,2)*p*first+3*(1-p)*p*p*second+pow(p,3)*landing
static func splash_alpha(progress: float) -> float:
 return maxf(0,1-progress/.65)
