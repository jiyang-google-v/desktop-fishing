extends Node

signal changed
const Model = preload("res://scripts/core/fishing_model.gd")
const Store = preload("res://scripts/core/save_store.gd")
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
var save_elapsed := 0.0
var last_saved := "尚未保存"
var save_failed := false
var safety_generation := ""

func _ready() -> void:
 rng.randomize()
 if "--tests" in OS.get_cmdline_user_args():
  set_process(false)
  return
 var loaded: Dictionary = store.read(save_path,model)
 if loaded.ok:
  state = loaded.state
  if loaded.get("migrated",false):
   warning = "已升级为番茄钟玩法，收藏保留；请重新设定并放竿。"
  prepare_restored_challenge()
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

func _notification(what: int) -> void:
 if what == NOTIFICATION_WM_CLOSE_REQUEST:
  request_exit()

func tick() -> void:
 var now: int = Time.get_ticks_msec()
 var wall: float = Time.get_unix_time_from_system()
 var elapsed: float = (now - last_tick) / 1000.0
 var wall_elapsed: float = wall - last_wall
 last_tick = now
 last_wall = wall
 focus_status = probe.sample()
 var was_complete: bool = model.completed(state)
 var was_paused: bool = state.paused
 advance_timer(elapsed,wall_elapsed,focus_status)
 if (not was_complete and model.completed(state)) or (not was_paused and state.paused):
  persist()
 save_elapsed += maxf(elapsed,0.0)
 if save_elapsed >= 30.0:
  persist()
  save_elapsed = 0.0
 changed.emit()

func persist() -> bool:
 if blocked:
  return false
 var had_save_failure := save_failed
 var result: Dictionary = store.write(save_path,state)
 save_failed = not result.ok
 if save_failed:
  warning = "存档写入失败，请检查磁盘空间和权限后重试。"
 else:
  if had_save_failure:
   warning = ""
  last_saved = Time.get_time_string_from_system()
 return result.ok

func commit(action: Callable) -> Dictionary:
 if blocked:
  return {"ok":false,"reason":"blocked"}
 var next: Dictionary = state.duplicate(true)
 var result: Dictionary = action.call(next)
 if result.ok:
  var saved: Dictionary = store.write(save_path,next)
  if not saved.ok:
   save_failed = true
   warning = "操作未保存，请检查磁盘空间后重试。"
   changed.emit()
   return {"ok":false,"reason":"save_failed"}
  save_failed = false
  last_saved = Time.get_time_string_from_system()
  state = next
  warning = ""
  reset_clock()
 changed.emit()
 return result

func cast_line() -> Dictionary:
 safety_generation = ""
 return commit(func(s): return model.cast_line(s))

func reel_line() -> Dictionary:
 return commit(func(s): return model.reel_line(s,Time.get_datetime_dict_from_system().hour,rng))

func settle(action: String, target_id: String = "") -> Dictionary:
 return commit(func(s): return model.settle(s,action,target_id))

func remove_from_tank(catch_id: String) -> Dictionary:
 return commit(func(s): return model.remove_from_tank(s,catch_id))

func remaining_seconds() -> float:
 return maxf(0,state.duration_minutes*60.0-state.focus_seconds)

func advance_timer(elapsed: float, _wall_elapsed: float, status: Dictionary) -> void:
 if not state.cast or state.paused or model.completed(state) or blocked:
  return
 if status.get('transient',false):
  return
 var cause := ''
 if not is_finite(elapsed) or elapsed <= 0 or elapsed > 5:
  cause = 'sleep'
 elif OS.get_name() == 'Windows' and not status.get('supported',false):
  cause = 'detection'
 elif status.get('locked',false):
  cause = 'locked'
 var generation: String = str(status.get('token',''))+':'+str(status.get('epoch',0))
 if cause.is_empty() and not safety_generation.is_empty() and generation != safety_generation:
  cause = 'system'
 safety_generation = generation
 if not cause.is_empty():
  state.paused = true
  state.pause_cause = cause
  return
 state.focus_seconds = minf(state.duration_minutes*60.0,state.focus_seconds+elapsed)

func pause_reason() -> String:
 if blocked:
  return 'blocked'
 if not state.pending_catch.is_empty():
  return 'pending'
 if not state.cast:
  return 'failed' if state.last_outcome == 'failed' else 'ready'
 if model.completed(state):
  return 'completed'
 if state.paused:
  return 'paused'
 return 'working'

func set_duration(minutes: int) -> Dictionary:
 return commit(func(s): return model.set_duration(s,minutes))

func toggle_pause() -> Dictionary:
 if not state.cast or model.completed(state):
  return {'ok':false,'reason':'not_active'}
 if state.paused and OS.get_name() == 'Windows':
  var safety: Dictionary = probe.sample() if probe != null else focus_status
  if not safety.get('supported',false) or safety.get('locked',true):
   return {'ok':false,'reason':'system_paused'}
  safety_generation = str(safety.get('token',''))+':'+str(safety.get('epoch',0))
 return commit(func(s):
  s.paused = not s.paused
  s.pause_cause = 'manual' if s.paused else ''
  return {'ok':true})

func fail_challenge() -> Dictionary:
 return commit(func(s): return model.fail_challenge(s))

func set_sound_enabled(enabled: bool) -> Dictionary:
 return commit(func(s):
  s.sound_enabled = enabled
  return {"ok":true})

func set_idle_minutes(minutes: int) -> Dictionary:
 if minutes not in [5,10,20]:
  return {"ok":false,"reason":"invalid_setting"}
 return commit(func(s):
  s.idle_minutes = minutes
  return {"ok":true})

func prepare_exit() -> bool:
 # A blocked/corrupt save must never be overwritten; leaving is still safe.
 if blocked:
  return true
 if not persist():
  warning = "保存失败，已取消退出。请检查磁盘空间和权限，再点击保存退出。"
  changed.emit()
  return false
 return true

func request_exit() -> void:
 if not prepare_exit():
  return
 if probe != null:
  probe.stop()
 get_tree().quit()

func retry_detection() -> void:
 if probe != null and OS.get_name() == "Windows":
  probe.start()
 focus_status = {"supported":false}
 reset_clock()
 changed.emit()

func diagnostic_text() -> String:
 var detail: String = probe.detail if probe != null else "not_started"
 return "版本：0.8.0-preview\n系统：%s\n状态：%s\n锁屏检测：%s\n设定时长：%d 分钟\n已完成：%.1f 秒\n剩余：%.1f 秒\n暂停原因：%s\n最近保存：%s\n保存失败：%s" % [OS.get_name(),pause_reason(),detail,state.duration_minutes,state.focus_seconds,remaining_seconds(),state.pause_cause,last_saved,str(save_failed)]

func prepare_restored_challenge() -> void:
 if state.cast and not model.completed(state):
  state.paused = true
  state.pause_cause = "restart"
