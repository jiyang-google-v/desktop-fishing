# Deterministic exports for the existing code-native UI system. Authored at 2x.
extends SceneTree
const DIR := 'res://assets/production/ui/pomodoro/'
func _initialize() -> void:
 var sources := {}
 sources.panel = '<rect x="2" y="2" width="364" height="148" rx="28" fill="#fff9ea" stroke="#83b8d8" stroke-width="4"/>'
 sources.track = '<rect x="1" y="1" width="318" height="18" rx="9" fill="#d8eaf1" stroke="#abcdda" stroke-width="2"/>'
 sources.fill = '<rect x="1" y="1" width="318" height="18" rx="9" fill="#75cddd" stroke="#68becf" stroke-width="2"/>'
 for symbol in ['pause','play']:
  for state in ['normal','hover','pressed','disabled']:
   var colors: Dictionary = {'normal':['#a8e3ed','#69b5d4'],'hover':['#c5eff2','#4e9fc5'],'pressed':['#7ac9db','#4b93b8'],'disabled':['#e0e9e7','#b5cacc']}
   var c: Array = colors[state]
   var ink: String = '#ffffff' if state != 'disabled' else '#a7babd'
   var shape: String = '<path d="M27 21 L44 32 L27 43 Z" fill="%s"/>' % ink if symbol == 'play' else '<rect x="24" y="21" width="5" height="22" rx="2" fill="%s"/><rect x="35" y="21" width="5" height="22" rx="2" fill="%s"/>' % [ink,ink]
   sources[symbol+'-'+state] = '<circle cx="32" cy="32" r="28" fill="%s" stroke="%s" stroke-width="3"/>' % [c[0],c[1]]+shape
 for id in sources:
  var dimensions := Vector2i(368,152) if id == 'panel' else (Vector2i(320,20) if id in ['track','fill'] else Vector2i(64,64))
  var svg: String = '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">%s</svg>' % [dimensions.x,dimensions.y,dimensions.x,dimensions.y,sources[id]]
  var file := FileAccess.open(DIR+id+'.svg',FileAccess.WRITE)
  file.store_string(svg+'\n')
  file.close()
  var image := Image.new()
  assert(image.load_svg_from_string(svg) == OK)
  image.convert(Image.FORMAT_RGBA8)
  assert(image.save_png(DIR+id+'.png') == OK)
 print('Exported 11 independent RGBA UI textures from editable SVG sources')
 quit()
