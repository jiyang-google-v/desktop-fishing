extends Node

signal changed
const Model = preload("res://scripts/core/fishing_model.gd")
const Store = preload("res://scripts/core/save_store.gd")
const Clock = preload("res://scripts/core/focus_clock.gd")
const Focus = preload("res://scripts/services/windows_focus.gd")
var model = Model.new()
var store = Store.new()
var state: Dictionary = model.fresh_state()
var focus_status: Dictionary = {"supported":false,"foreground":true,"locked":true,"idle_seconds":-1.0}
var warning := ""
var blocked := false
var save_path := "user://save.json"
var probe
var rng := RandomNumberGenerator.new()
var last_tick := 0
var last_wall := 0.0
var clock = Clock.new()
var save_elapsed := 0.0

func _ready() -> void:
 rng.randomize()
 if "--tests" in OS.get_cmdline_user_args():
  set_process(false)
  return
 var loaded: Dictionary = store.read(save_path,model)
 if loaded.ok:
  state = loaded.state
  if loaded.get("recovered",false):
   warning = "主存档损坏，已恢复上一份备份。"
 else:
  blocked = true
  warning = "存档版本不兼容，已暂停以保护数据。" if loaded.reason == "version" else "存档与备份无法读取，已暂停操作。"
 probe = Focus.new()
 add_child(probe)
 reset_clock()
 var timer := Timer.new()
 timer.wait_time = 1.0
 timer.timeout.connect(tick)
 add_child(timer)
 timer.start()

func reset_clock() -> void:
 last_tick = Time.get_ticks_msec()
 last_wall = Time.get_unix_time_from_system()
 clock.reset()

func _notification(what: int) -> void:
 if what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
  reset_clock()
 if what == NOTIFICATION_WM_CLOSE_REQUEST:
  persist()
  if probe != null:
   probe.stop()
  get_tree().quit()

func tick() -> void:
 var now: int = Time.get_ticks_msec()
 var wall: float = Time.get_unix_time_from_system()
 var elapsed: float = (now - last_tick) / 1000.0
 var wall_elapsed: float = wall - last_wall
 last_tick = now
 last_wall = wall
 focus_status = probe.sample()
 # Pause conservatively for stale readings, foreground and clock/sleep gaps.
 var sequence: int = int(focus_status.get("sequence",-1))
 var eligible: bool = not blocked and state.cast and model.can_accrue(focus_status) and not get_window().has_focus()
 var accrued: float = clock.advance(elapsed,wall_elapsed,eligible,sequence)
 state.focus_seconds = minf(Model.MAX_SECONDS,state.focus_seconds + accrued)
 save_elapsed += elapsed
 if save_elapsed >= 30.0:
  persist()
  save_elapsed = 0.0
 changed.emit()

func persist() -> bool:
 if blocked:
  return false
 var result: Dictionary = store.write(save_path,state)
 if not result.ok:
  warning = "存档写入失败，请检查磁盘空间和权限。"
 return result.ok

func commit(action: Callable) -> Dictionary:
 if blocked:
  return {"ok":false,"reason":"blocked"}
 var next: Dictionary = state.duplicate(true)
 var result: Dictionary = action.call(next)
 if result.ok:
  var saved: Dictionary = store.write(save_path,next)
  if not saved.ok:
   warning = "操作未保存，请检查磁盘空间后重试。"
   changed.emit()
   return {"ok":false,"reason":"save_failed"}
  state = next
  warning = ""
  reset_clock()
 changed.emit()
 return result

func cast_line() -> Dictionary:
 return commit(func(s): return model.cast_line(s))

func reel_line() -> Dictionary:
 return commit(func(s): return model.reel_line(s,Time.get_datetime_dict_from_system().hour,rng))

func settle(action: String, target_id: String = "") -> Dictionary:
 return commit(func(s): return model.settle(s,action,target_id))

func remove_from_tank(catch_id: String) -> Dictionary:
 return commit(func(s): return model.remove_from_tank(s,catch_id))

func pause_reason() -> String:
 if blocked:
  return "blocked"
 if not state.pending_catch.is_empty():
  return "pending"
 if not state.cast:
  return "ready"
 if get_window().has_focus() or focus_status.get("foreground",true):
  return "foreground"
 if not focus_status.get("supported",false):
  return "unsupported"
 if focus_status.get("locked",true):
  return "locked"
 if focus_status.get("idle_seconds",-1.0) > Model.IDLE_SECONDS:
  return "idle"
 if state.focus_seconds >= Model.MAX_SECONDS:
  return "max_depth"
 return "working"
