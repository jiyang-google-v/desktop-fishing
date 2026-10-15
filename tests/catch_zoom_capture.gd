extends SceneTree
var folder := 'res://docs/qa/card-polish/'
func _initialize() -> void:
 call_deferred('run')
func capture(window: Window, file: String) -> void:
 for i in 5:
  await process_frame
 RenderingServer.force_draw()
 window.get_texture().get_image().save_png(folder+file+'.png')
func run() -> void:
 DirAccess.make_dir_recursive_absolute(folder)
 var main=load('res://scenes/main.tscn').instantiate()
 root.add_child(main)
 await process_frame
 var game=root.get_node('Game')
 var layouts=main.layouts
 for mode in ['scene','mini']:
  game.state=game.model.fresh_state()
  layouts.apply(mode,false)
  layouts.set_process(false)
  layouts.tools.hide()
  layouts.view.action='idle'
  layouts.view.line_cast=true
  for zoom in [.75,1.0,2.0]:
   layouts.set_zoom(zoom)
   await capture(root,mode+'-'+str(roundi(zoom*100)))
  layouts.set_zoom(1)
 var popup=layouts.catch_popup
 for f in game.model.roster:
  game.state=game.model.fresh_state()
  game.state.pending_catch={'catch_id':'qa-'+f.id,'species_id':f.id,'length_cm':12.3,'duration_minutes':25,'first_discovery':true,'new_record':true}
  game.state.encyclopedia[f.id]={'count':1,'record_cm':12.3}
  popup.present(game)
  popup.show()
  popup.reveal_age=2
  for i in 5:
   await process_frame
  assert(Rect2(Vector2.ZERO,Vector2(popup.size)).encloses(popup.later_button.get_global_rect()),'Card footer must fit for '+f.id)
  assert(popup.knowledge.size.x<=popup.size.x)
  if f.id in ['fish_001_clownfish','fish_010_bigeye_tuna','fish_012_star_wish_fish']:
   await capture(popup,f.id)
 popup.hide()
 game.state=game.model.fresh_state()
 for i in 6:
  game.state.aquarium.append({'catch_id':'tank-'+str(i),'species_id':game.model.roster[i].id,'length_cm':12.3})
 main.open_collection('tank')
 await capture(main.collection,'tank-filled')
 assert(main.aquarium_view.size.y>main.collection.size.y*.5)
 main.select_tank_fish('tank-0')
 await capture(main.collection,'tank-selected')
 main.close_collection()
 game.model.cast_line(game.state)
 game.state.focus_seconds=game.state.duration_minutes*60.0
 for mode in ['scene','mini']:
  layouts.apply(mode,false)
  layouts.sync_tools()
  await capture(root,mode+'-completed')
 main.open_collection('book')
 await capture(main.collection,'book-encyclopedia')
 print('Captured native zoom extremes, large fish cards and encyclopedia; all 14 card footers fit')
 quit()
