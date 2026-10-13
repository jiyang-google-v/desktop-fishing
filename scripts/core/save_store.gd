extends RefCounted

func parse_file(path: String):
 var json := JSON.new()
 if json.parse(FileAccess.get_file_as_string(path)) != OK:
  return null
 return json.data

func read(path: String, model) -> Dictionary:
 if not FileAccess.file_exists(path) and not FileAccess.file_exists(path + ".bak"):
  return {"ok":true,"state":model.fresh_state(),"recovered":false}
 var main = model.restore(parse_file(path)) if FileAccess.file_exists(path) else {"ok":false,"reason":"corrupt"}
 if main.ok:
  main.recovered = false
  return main
 if main.reason == "version":
  return {"ok":false,"reason":"version"}
 if FileAccess.file_exists(path + ".bak"):
  var backup = model.restore(parse_file(path + ".bak"))
  if backup.ok:
   backup.recovered = true
   return backup
 return {"ok":false,"reason":"corrupt"}

func write(path: String, state: Dictionary) -> Dictionary:
 var absolute: String = ProjectSettings.globalize_path(path)
 var previous = parse_file(path) if FileAccess.file_exists(path) else null
 if previous is Dictionary and not valid_version(previous.get("version",0)):
  return {"ok":false,"reason":"version"}
 var file = FileAccess.open(path + ".tmp",FileAccess.WRITE)
 if file == null:
  return {"ok":false,"reason":"save_failed"}
 file.store_string(JSON.stringify(state,"  "))
 file.flush()
 var write_error: Error = file.get_error()
 file.close()
 if write_error != OK:
  return {"ok":false,"reason":"save_failed"}
 if previous is Dictionary and previous.has("version"):
  var copied: Error = DirAccess.copy_absolute(absolute,absolute + ".bak.tmp")
  if copied != OK or DirAccess.rename_absolute(absolute + ".bak.tmp",absolute + ".bak") != OK:
   return {"ok":false,"reason":"save_failed"}
 var error: Error = DirAccess.rename_absolute(absolute + ".tmp",absolute)
 return {"ok":error == OK,"reason":"" if error == OK else "save_failed"}

func valid_version(value) -> bool:
 return (value is float or value is int) and float(value) in [1.0,2.0,3.0]
