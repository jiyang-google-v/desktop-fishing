extends RefCounted

const Policy = preload("res://scripts/core/focus_policy.gd")
const MAX_SECONDS := 3000.0
const MAX_DEPTH := 200.0
const IDLE_SECONDS := 600.0
const WEIGHTS := {"common":60.0,"uncommon":25.0,"rare":9.0,"legendary":1.0}
var roster: Array = []

func _init() -> void:
 var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/fish-data.json"))
 if parsed is Array:
  roster = parsed

func new_id() -> String:
 return Crypto.new().generate_random_bytes(16).hex_encode()

func fresh_state() -> Dictionary:
 return {"version":3,"idle_minutes":10,"cast":false,"session_id":"","focus_seconds":0.0,"encyclopedia":{},"aquarium":[],"pending_catch":{}}

func depth_for(seconds: float) -> float:
 return clampf(seconds * 4.0 / 60.0,0.0,MAX_DEPTH)

func can_accrue(status: Dictionary, idle_minutes: int = 10) -> bool:
 var idle = status.get("idle_seconds",-1.0)
 if not (idle is float or idle is int):
  return false
 return status.get("supported",false) and not status.get("foreground",true) and not status.get("locked",true) and is_finite(float(idle)) and idle >= 0 and idle <= Policy.idle_minutes(idle_minutes) * 60

func eligible_fish(depth: float, night: bool) -> Array:
 return roster.filter(func(f): return depth >= f.minDepth and depth <= f.maxDepth and (f.time != "night" or night))

func cast_line(s: Dictionary) -> Dictionary:
 if s.cast or not s.pending_catch.is_empty():
  return {"ok":false,"reason":"pending" if not s.pending_catch.is_empty() else "already_cast"}
 s.cast = true
 s.session_id = new_id()
 s.focus_seconds = 0.0
 return {"ok":true}

func reel_line(s: Dictionary, hour: int, rng: RandomNumberGenerator) -> Dictionary:
 if not s.cast:
  return {"ok":false,"reason":"not_cast"}
 var depth: float = depth_for(s.focus_seconds)
 var candidates: Array = eligible_fish(depth,hour < 6 or hour >= 18)
 s.cast = false
 if candidates.is_empty():
  s.session_id = ""
  return {"ok":true,"empty":true}
 var total := 0.0
 for f in candidates:
  total += WEIGHTS.get(f.rarity,1.0)
 var roll: float = rng.randf() * total
 var selected: Dictionary = candidates.back()
 for f in candidates:
  roll -= WEIGHTS.get(f.rarity,1.0)
  if roll < 0:
   selected = f
   break
 var length: float = snappedf(10.0 + rng.randf() * 70.0,0.1)
 var record: Dictionary = s.encyclopedia.get(selected.id,{"count":0,"record_cm":0.0})
 s.encyclopedia[selected.id] = {"count":record.count + 1,"record_cm":maxf(record.record_cm,length)}
 s.pending_catch = {"catch_id":new_id(),"species_id":selected.id,"length_cm":length,"depth":depth,"caught_at":Time.get_datetime_string_from_system(true)}
 return {"ok":true}

func settle(s: Dictionary, action: String, target_id: String = "") -> Dictionary:
 if s.pending_catch.is_empty():
  return {"ok":false,"reason":"no_catch"}
 if action == "keep":
  if s.aquarium.size() >= 6:
   return {"ok":false,"reason":"full"}
  s.aquarium.append(s.pending_catch.duplicate(true))
 elif action == "replace":
  var index: int = find_catch(s.aquarium,target_id)
  if index < 0:
   return {"ok":false,"reason":"unknown"}
  s.aquarium[index] = s.pending_catch.duplicate(true)
 elif action != "release":
  return {"ok":false,"reason":"invalid_action"}
 s.pending_catch = {}
 s.session_id = ""
 return {"ok":true}

func find_catch(tank: Array, catch_id: String) -> int:
 for i in range(tank.size()):
  if tank[i].catch_id == catch_id:
   return i
 return -1

func remove_from_tank(s: Dictionary, catch_id: String) -> Dictionary:
 var index: int = find_catch(s.aquarium,catch_id)
 if index < 0:
  return {"ok":false,"reason":"unknown"}
 s.aquarium.remove_at(index)
 return {"ok":true}

func finite_number(value, maximum: float) -> float:
 if not (value is float or value is int) or not is_finite(float(value)):
  return 0.0
 return clampf(float(value),0.0,maximum)

func species(id: String) -> Dictionary:
 for f in roster:
  if f.id == id:
   return f
 return {}

func clean_catch(value, camel_case: bool = false) -> Dictionary:
 if not value is Dictionary:
  return {}
 var cid = value.get("catchId" if camel_case else "catch_id","")
 var sid = value.get("speciesId" if camel_case else "species_id","")
 var length = value.get("lengthCm" if camel_case else "length_cm",-1)
 if not cid is String or cid.is_empty() or not sid is String or species(sid).is_empty():
  return {}
 if not (length is float or length is int) or not is_finite(float(length)) or length < 0:
  return {}
 return {"catch_id":cid,"species_id":sid,"length_cm":float(length),"depth":finite_number(value.get("depth",0),MAX_DEPTH),"caught_at":str(value.get("caughtAt" if camel_case else "caught_at",""))}

func restore(data) -> Dictionary:
 if not data is Dictionary:
  return {"ok":false,"reason":"corrupt"}
 if not data.has("version"):
  return {"ok":false,"reason":"corrupt"}
 var raw_version = data.get("version",0)
 if not (raw_version is float or raw_version is int) or float(raw_version) not in [1.0,2.0,3.0]:
  return {"ok":false,"reason":"version"}
 var version: int = int(raw_version)
 if version == 3:
  for key in ["cast","session_id","focus_seconds","encyclopedia","aquarium","pending_catch"]:
   if not data.has(key):
    return {"ok":false,"reason":"corrupt"}
  if not data.cast is bool or not data.session_id is String or not data.encyclopedia is Dictionary or not data.aquarium is Array or not data.pending_catch is Dictionary:
   return {"ok":false,"reason":"corrupt"}
  if not (data.focus_seconds is int or data.focus_seconds is float) or not is_finite(float(data.focus_seconds)):
   return {"ok":false,"reason":"corrupt"}
 var camel: bool = version < 3
 var s: Dictionary = fresh_state()
 s.idle_minutes = Policy.idle_minutes(data.get("idle_minutes",10))
 s.focus_seconds = finite_number(data.get("focusSeconds" if camel else "focus_seconds",0),MAX_SECONDS)
 var book = data.get("encyclopedia",{})
 if book is Dictionary:
  for id in book:
   if id is String and not species(id).is_empty() and book[id] is Dictionary:
    s.encyclopedia[id] = {"count":int(finite_number(book[id].get("count",0),1000000000)),"record_cm":finite_number(book[id].get("recordCm" if camel else "record_cm",0),100000)}
 var tank = data.get("aquarium",[])
 var seen := {}
 if tank is Array:
  for i in range(tank.size()):
   var value = tank[i]
   if version == 1 and value is String:
    value = {"catch_id":"legacy-%d" % i,"species_id":value,"length_cm":s.encyclopedia.get(value,{}).get("record_cm",0.0)}
   var c: Dictionary = clean_catch(value,camel and version != 1)
   if not c.is_empty() and not seen.has(c.catch_id) and s.aquarium.size() < 6:
    s.aquarium.append(c)
    seen[c.catch_id] = true
 if version >= 2:
  var pending: Dictionary = clean_catch(data.get("pendingCatch" if camel else "pending_catch",{}),camel)
  if not pending.is_empty() and not seen.has(pending.catch_id):
   s.pending_catch = pending
  s.cast = data.get("cast",false) == true and s.pending_catch.is_empty()
  var session = data.get("sessionId" if camel else "session_id","")
  s.session_id = session if session is String else ""
  if s.cast and s.session_id.is_empty():
   s.session_id = new_id()
 return {"ok":true,"state":s}
