extends Node

const Sample = preload("res://scripts/core/focus_sample.gd")
const RETRY_MS := 15000
const STARTUP_MS := 45000
const STALL_MS := 10000
var worker_pid := -1
var token := ""
var status_path := ""
var script_path := ""
var attempts := 0
var started_at := 0
var next_retry := 0
var last_sequence := -1
var last_fresh_at := 0
var detail := "starting"
var last_sample: Dictionary = {}

func _ready() -> void:
 if OS.get_name() == "Windows":
  start()

func start() -> void:
 stop()
 attempts += 1
 started_at = Time.get_ticks_msec()
 last_fresh_at = started_at
 next_retry = started_at + RETRY_MS
 last_sequence = -1
 last_sample.clear()
 detail = "starting"
 token = Crypto.new().generate_random_bytes(16).hex_encode()
 status_path = "user://focus-%s.json" % token
 script_path = "user://focus-worker-%s.ps1" % token
 var script = FileAccess.open(script_path,FileAccess.WRITE)
 if script == null:
  detail = "script_write_failed"
  return
 script.store_string(FileAccess.get_file_as_string("res://platform/windows/focus-worker.ps1"))
 script.close()
 worker_pid = OS.create_process("powershell.exe",PackedStringArray(["-NoProfile","-NonInteractive","-WindowStyle","Hidden","-ExecutionPolicy","Bypass","-File",ProjectSettings.globalize_path(script_path),"-ParentProcessId",str(OS.get_process_id()),"-OutputPath",ProjectSettings.globalize_path(status_path),"-Token",token]),false)
 if worker_pid <= 0:
  detail = "launch_failed"

func sample() -> Dictionary:
 var paused := {"supported":false,"foreground":true,"locked":true,"idle_seconds":-1.0,"sequence":-1}
 if OS.get_name() != "Windows":
  detail = "platform"
  return paused
 var now := Time.get_ticks_msec()
 if worker_pid <= 0 or not OS.is_process_running(worker_pid):
  detail = "worker_exited"
  if now >= next_retry:
   start()
  return paused
 var value = null
 if FileAccess.file_exists(status_path):
  # A worker replacement can briefly leave an empty/partial read; fail closed without an engine error.
  var parser := JSON.new()
  if parser.parse(FileAccess.get_file_as_string(status_path)) == OK:
   value = parser.data
 return consume(value,Time.get_unix_time_from_system(),now)

func consume(value, wall_now: float, now: int) -> Dictionary:
 var valid: Dictionary = Sample.validate(value,token,wall_now)
 if not valid.is_empty() and int(valid.sequence) > last_sequence:
  last_sequence = int(valid.sequence)
  last_fresh_at = now
  last_sample = valid.duplicate(true)
  detail = 'ok'
  return valid
 # The helper publishes every 500ms. Multiple readers can legitimately see
 # the same sequence; atomic replacement can also briefly yield no JSON.
 var cached: Dictionary = Sample.validate(last_sample,token,wall_now)
 if not cached.is_empty() and int(cached.sequence) == last_sequence:
  detail = 'ok_cached'
  return cached
 detail = 'starting' if last_sequence < 0 else 'checking'
 var timeout: int = STARTUP_MS if last_sequence < 0 else STALL_MS
 if now-last_fresh_at >= timeout:
  detail = 'retry_wait'
  stop()
  next_retry = now+RETRY_MS
  return {'supported':false,'locked':true,'transient':false}
 # Do not award unverified time, but a sub-watchdog sampling gap must not
 # turn into a permanent manual-resume pause.
 return {'supported':false,'locked':false,'transient':true}

func stop() -> void:
 if worker_pid > 0 and OS.is_process_running(worker_pid):
  OS.kill(worker_pid)
 worker_pid = -1
 if not status_path.is_empty():
  for suffix in ["", ".tmp"]:
   DirAccess.remove_absolute(ProjectSettings.globalize_path(status_path + suffix))
 if not script_path.is_empty():
  DirAccess.remove_absolute(ProjectSettings.globalize_path(script_path))

func _exit_tree() -> void:
 stop()
