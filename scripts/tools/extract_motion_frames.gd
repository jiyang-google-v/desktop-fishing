extends SceneTree
## Mechanical fixed-grid extraction only. Generated artwork is never redrawn here.
func bounds(image: Image, threshold: int = 32, start_y: int = 0) -> Rect2i:
 var data := image.get_data()
 var left := image.get_width()
 var top := image.get_height()
 var right := -1
 var bottom := -1
 for y in range(start_y,image.get_height()):
  for x in range(image.get_width()):
   if data[(y*image.get_width()+x)*4+3] >= threshold:
    left = mini(left,x)
    top = mini(top,y)
    right = maxi(right,x)
    bottom = maxi(bottom,y)
 return Rect2i(left,top,right-left+1,bottom-top+1)

func foot_anchor(image: Image, shape: Rect2i) -> Vector2:
 var pixels := image.get_data()
 var sum_x := 0.0
 var weight := 0.0
 for y in range(shape.position.y+roundi(shape.size.y*.84),shape.end.y):
  for x in range(shape.position.x,shape.end.x):
   var alpha: float = pixels[(y*image.get_width()+x)*4+3]
   if alpha >= 32:
    sum_x += x*alpha
    weight += alpha
 return Vector2(sum_x/maxf(weight,1.0),shape.end.y)

func _initialize() -> void:
 var jobs: Array = JSON.parse_string(FileAccess.get_file_as_string("res://art/concepts/motion/sources.json"))
 var registrations: Array = []
 for job in jobs:
  var source := Image.load_from_file("res://art/concepts/motion/" + str(job.get("source",job.id)) + ".png")
  assert(source != null and source.get_format() == Image.FORMAT_RGBA8, "Real RGBA source " + job.id)
  var columns: int = job.columns
  var rows: int = job.rows
  DirAccess.make_dir_recursive_absolute("res://" + job.directory)
  var cells: Array[Image] = []
  var heights: Array[float] = []
  for index in range(int(job.count)):
   var x: int = index % columns
   var y: int = index / columns
   var left: int = roundi(source.get_width() * float(x) / columns)
   var top: int = roundi(source.get_height() * float(y) / rows)
   var right: int = roundi(source.get_width() * float(x+1) / columns)
   var bottom: int = roundi(source.get_height() * float(y+1) / rows)
   var region := Rect2i(left,top,right-left,bottom-top)
   if job.has("source_rects"):
    var rect: Array = job.source_rects[index]
    region = Rect2i(int(rect[0]),int(rect[1]),int(rect[2]),int(rect[3]))
   var frame := source.get_region(region)
   if job.has("source_masks"):
    # Extract the selected full silhouette, excluding neighbouring frame fragments.
    # RLE regions preserve original RGBA pixels including the antialiased edge.
    var runs: Array = JSON.parse_string(FileAccess.get_file_as_string("res://"+str(job.source_masks[index])))
    var isolated := Image.create(frame.get_width(),frame.get_height(),false,Image.FORMAT_RGBA8)
    for run in runs:
     isolated.blit_rect(frame,Rect2i(int(run[1]),int(run[0]),int(run[2]),1),Vector2i(int(run[1]),int(run[0])))
    frame = isolated
   if not job.has("source_rects") and (not job.id.begins_with("gear-") or job.clip == "rod"):
    frame.resize(int(job.canvas),int(job.canvas),Image.INTERPOLATE_LANCZOS)
   cells.append(frame)
   heights.append(float(bounds(frame).size.y))
  heights.sort()
  var character: bool = job.id.begins_with("fisher-") or job.id.begins_with("cat-")
  var target_height := .84 if job.id.begins_with("fisher-") else .70
  var clip_scale: float = float(job.canvas)*target_height/heights[heights.size()/2] if character else 1.0
  for index in cells.size():
   var frame: Image = cells[index]
   var offset := Vector2i.ZERO
   if character:
    var shape := bounds(frame)
    var anchor := foot_anchor(frame,shape)
    frame.resize(roundi(frame.get_width()*clip_scale),roundi(frame.get_height()*clip_scale),Image.INTERPOLATE_LANCZOS)
    var target := Vector2(.70,.94) if job.id.begins_with("fisher-") else Vector2(.58,.82)
    offset = Vector2i((target*float(job.canvas)-anchor*clip_scale).round())
    var canvas := Image.create(int(job.canvas),int(job.canvas),false,Image.FORMAT_RGBA8)
    canvas.blit_rect(frame,Rect2i(Vector2i.ZERO,frame.get_size()),offset)
    frame = canvas
   elif job.id in ["fx-splash","fx-ripple"]:
    var shape := bounds(frame)
    var factor := .85
    var anchor := Vector2(shape.get_center().x,shape.end.y) if job.clip == "splash" else Vector2(shape.get_center())
    var target := Vector2(.5,.82) if job.clip == "splash" else Vector2(.5,.5)
    frame.resize(roundi(frame.get_width()*factor),roundi(frame.get_height()*factor),Image.INTERPOLATE_LANCZOS)
    offset = Vector2i((target*float(job.canvas)-anchor*factor).round())
    var canvas := Image.create(int(job.canvas),int(job.canvas),false,Image.FORMAT_RGBA8)
    canvas.blit_rect(frame,Rect2i(Vector2i.ZERO,frame.get_size()),offset)
    frame = canvas
   elif job.id.begins_with("gear-") and job.clip != "rod":
    var shape := bounds(frame)
    var crop := frame.get_region(shape)
    var factor: float = float(job.canvas)*.65/maxi(crop.get_width(),crop.get_height())
    crop.resize(roundi(crop.get_width()*factor),roundi(crop.get_height()*factor),Image.INTERPOLATE_LANCZOS)
    frame = Image.create(int(job.canvas),int(job.canvas),false,Image.FORMAT_RGBA8)
    frame.blit_rect(crop,Rect2i(Vector2i.ZERO,crop.get_size()),(Vector2i.ONE*int(job.canvas)-crop.get_size())/2)
   var filename: String = job.get("file","%s-%02d.png" % [job.clip,index+1])
   assert(frame.save_png("res://%s/%s" % [job.directory,filename]) == OK)
   registrations.append({"source":job.id,"frame":filename,"scale":clip_scale,"offset":[offset.x,offset.y]})
 var record := FileAccess.open("res://docs/qa/stage4/frame-registration.json",FileAccess.WRITE)
 record.store_string(JSON.stringify(registrations,"  "))
 print("Authored motion frames extracted on fixed transparent canvases")
 quit()
