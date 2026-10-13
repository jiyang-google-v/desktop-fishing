extends Node

var worker_pid := -1
var token := ""
var status_path := ""
var script_path := ""
var attempts := 0

func _ready() -> void:
 if OS.get_name() == "Windows":
  start()

func start() -> void:
 attempts += 1
 token = Crypto.new().generate_random_bytes(16).hex_encode()
 status_path = "user://focus-%s.json" % token
 script_path = "user://focus-worker.ps1"
 var script = FileAccess.open(script_path,FileAccess.WRITE)
 if script == null:
  return
 script.store_string(FileAccess.get_file_as_string("res://platform/windows/focus-worker.ps1"))
 script.close()
 worker_pid = OS.create_process("powershell.exe",PackedStringArray(["-NoProfile","-NonInteractive","-WindowStyle","Hidden","-ExecutionPolicy","Bypass","-File",ProjectSettings.globalize_path(script_path),"-ParentProcessId",str(OS.get_process_id()),"-OutputPath",ProjectSettings.globalize_path(status_path),"-Token",token]),false)

func sample() -> Dictionary:
 var paused := {"supported":false,"foreground":true,"locked":true,"idle_seconds":-1.0,"sequence":-1}
 if OS.get_name() != "Windows":
  return paused
 if worker_pid <= 0 or not OS.is_process_running(worker_pid):
  if attempts < 3:
   start()
  return paused
 if not FileAccess.file_exists(status_path):
  return paused
 var value = JSON.parse_string(FileAccess.get_file_as_string(status_path))
 if not value is Dictionary or value.get("token","") != token:
  return paused
 var age: float = Time.get_unix_time_from_system() - float(value.get("sampled_at",0))
 if age < 0 or age > 3.0 or not value.get("supported",false):
  return paused
 return value

func stop() -> void:
 if worker_pid > 0 and OS.is_process_running(worker_pid):
  OS.kill(worker_pid)
 worker_pid = -1
 if not status_path.is_empty():
  for suffix in ["", ".tmp"]:
   DirAccess.remove_absolute(ProjectSettings.globalize_path(status_path + suffix))

func _exit_tree() -> void:
 stop()
