extends SceneTree
const Ocean = preload("res://scripts/ui/ocean_view.gd")
var failures := 0
var finished := 0
var splashes := 0
func check(ok: bool, message: String) -> void:
 if not ok:
  failures += 1
  push_error(message)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var ocean = Ocean.new()
 root.add_child(ocean)
 ocean.set_process(false)
 ocean.animation_finished.connect(func(): finished += 1)
 ocean.splash.connect(func(): splashes += 1)
 ocean.play("reel")
 ocean.show_catch(true)
 check(ocean.actor_clip() == "reel" and ocean.cat_clip() == "alert", "Do not celebrate before reveal")
 ocean.play("cast")
 check(ocean.motion.active == "reel", "Repeated action cannot replace reel")
 ocean.skip()
 check(finished == 1 and ocean.actor_clip() == "happy" and ocean.cat_clip() == "happy", "Skip reveals catch and reacts once")
 ocean.skip()
 check(finished == 1, "Repeated skip has no duplicate completion")
 ocean.reaction_age = 10
 ocean.phase = .2
 check(ocean.actor_clip() == "idle" and ocean.cat_clip() == "blink", "Reaction returns to calm idle and periodic blink")
 ocean.show_catch(false)
 ocean.working = false
 var progress_before: float = ocean.progress_phase
 var phase_before: float = ocean.phase
 ocean._process(.2)
 check(ocean.progress_phase == progress_before and ocean.phase > phase_before, "Pause freezes exploration while ambient animation continues")
 ocean.working = true
 ocean._process(.2)
 check(ocean.progress_phase > progress_before, "Focus resumes exploration without resetting it")
 ocean.play("cast")
 ocean._process(.9)
 ocean._process(.1)
 check(splashes == 1, "Crossing splash marker triggers one sound/event")
 ocean._process(10)
 check(finished == 2 and not ocean.is_busy(), "Long frame completes action exactly once")
 ocean.queue_free()
 print("Stage 4 reaction/skip/pause UI checks: failures=%d" % failures)
 quit(1 if failures else 0)
