extends Control
const MANIFEST_PATH := "res://assets/production/collection_manifest.json"
static var textures := {}
static var visible_bounds := {}
var fit_visible := false
var species_id := ""
var silhouette := false
var facing := 1.0

static func texture_for(id: String) -> Texture2D:
 if textures.is_empty() and FileAccess.file_exists(MANIFEST_PATH):
  var manifest = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
  for asset in manifest.assets:
   textures[asset.id] = load("res://"+asset.path)
   if asset.has('display_rect'):
    var bounds: Array = asset.display_rect
    visible_bounds[asset.id] = Rect2(float(bounds[0]),float(bounds[1]),float(bounds[2]),float(bounds[3]))
 return textures.get(id,null)

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 resized.connect(queue_redraw)

func _draw() -> void:
 var texture := texture_for(species_id)
 if texture == null:
  draw_string(ThemeDB.fallback_font,Vector2(size.x*.5-8,size.y*.55),"?",HORIZONTAL_ALIGNMENT_CENTER,-1,24,Color("8fa7ad"))
  return
 var tint := Color("a7b9bd") if silhouette else Color.WHITE
 if silhouette:
  # Shader keeps alpha but replaces RGB with a uniform silhouette.
  if material == null:
   var shader := Shader.new()
   shader.code = "shader_type canvas_item; void fragment(){ vec4 t=texture(TEXTURE,UV); COLOR=vec4(vec3(0.61,0.70,0.72),t.a); }"
   var shader_material := ShaderMaterial.new()
   shader_material.shader = shader
   material = shader_material
 if fit_visible:
  if not visible_bounds.has(species_id):
   var bitmap := texture.get_image()
   visible_bounds[species_id] = bitmap.get_used_rect() if bitmap != null else Rect2i(Vector2i.ZERO,Vector2i(texture.get_size()))
  var source: Rect2 = Rect2(visible_bounds[species_id])
  if source.has_area():
   var factor: float = minf(size.x*.90/source.size.x,size.y*.90/source.size.y)
   var dimensions := source.size*factor
   draw_texture_rect_region(texture,Rect2((size-dimensions)*.5,dimensions),source,tint)
  return
 var side: float = minf(size.x,size.y)
 draw_set_transform(size*.5,0,Vector2(facing,1))
 draw_texture_rect(texture,Rect2(Vector2.ONE*-side*.5,Vector2.ONE*side),false,tint)
 draw_set_transform(Vector2.ZERO)
