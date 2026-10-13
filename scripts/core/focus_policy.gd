extends RefCounted

static func idle_minutes(value) -> int:
 if (value is int or value is float) and float(value) in [5.0,10.0,20.0]:
  return int(value)
 return 10

static func reason(state: Dictionary, status: Dictionary, blocked: bool, window_focused: bool) -> String:
 if blocked:
  return "blocked"
 if not state.pending_catch.is_empty():
  return "pending"
 if not state.cast:
  return "ready"
 if not status.get("supported",false):
  return "unsupported"
 if status.get("locked",true):
  return "locked"
 if window_focused or status.get("foreground",true):
  return "foreground"
 var idle = status.get("idle_seconds",-1)
 if not (idle is float or idle is int) or not is_finite(float(idle)) or idle < 0:
  return "unsupported"
 if idle > idle_minutes(state.get("idle_minutes",10)) * 60:
  return "idle"
 if state.focus_seconds >= 3000.0:
  return "max_depth"
 return "working"
