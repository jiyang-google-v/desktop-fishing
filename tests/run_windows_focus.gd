extends SceneTree

const Focus = preload("res://scripts/services/windows_focus.gd")
var failures := 0

func _initialize() -> void:
 call_deferred("run")

func check(ok: bool, message: String) -> void:
 if not ok:
  failures += 1
  push_error(message)

func wait_for_sample(probe) -> Dictionary:
 var deadline: int = Time.get_ticks_msec() + 30000
 while Time.get_ticks_msec() < deadline:
  await create_timer(0.6).timeout
  var value: Dictionary = probe.sample()
  if value.get("supported",false):
   return value
 return {}

func run() -> void:
 if OS.get_name() != "Windows":
  print("Windows integration skipped on non-Windows host")
  quit()
  return
 var probe = Focus.new()
 root.add_child(probe)
 var first: Dictionary = await wait_for_sample(probe)
 check(not first.is_empty(), "Native worker starts and validates")
 var old_token: String = probe.token
 var old_path: String = probe.status_path
 var old_script: String = probe.script_path
 OS.kill(probe.worker_pid)
 await create_timer(0.5).timeout
 probe.next_retry = 0
 check(not probe.sample().supported, "Worker exit pauses immediately")
 var recovered: Dictionary = await wait_for_sample(probe)
 check(not recovered.is_empty() and probe.token != old_token, "Worker restarts automatically")
 check(not FileAccess.file_exists(old_path) and not FileAccess.file_exists(old_script), "Restart removes old worker files")
 # Force the stale-sequence watchdog path without changing system settings.
 probe.last_sequence = 9223372036854775806
 probe.last_fresh_at = Time.get_ticks_msec() - 11000
 check(not probe.sample().supported and probe.worker_pid == -1, "Stalled worker stopped")
 probe.next_retry = 0
 probe.sample()
 check(not (await wait_for_sample(probe)).is_empty(), "Watchdog retry recovers")
 var pid: int = probe.worker_pid
 var path: String = probe.status_path
 var script: String = probe.script_path
 probe.stop()
 await create_timer(0.5).timeout
 check(not OS.is_process_running(pid), "Worker terminated on exit")
 check(not FileAccess.file_exists(path) and not FileAccess.file_exists(script), "Exit removes helper files")
 probe.queue_free()
 print("Windows worker lifecycle: failures=%d" % failures)
 quit(1 if failures else 0)
