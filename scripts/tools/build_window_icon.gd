extends SceneTree
func _initialize() -> void:
 var texture = load('res://assets/production/ui/app-icon.svg')
 var image: Image = texture.get_image()
 assert(image.save_png('res://assets/production/ui/app-icon.png') == OK)
 quit()
