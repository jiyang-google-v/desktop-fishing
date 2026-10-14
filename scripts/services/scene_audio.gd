extends Node
const WATER = preload("res://assets/production/audio/water.wav")
const CAST = preload("res://assets/production/audio/cast.wav")
const REEL = preload("res://assets/production/audio/reel.wav")
var ambience: AudioStreamPlayer
var effect: AudioStreamPlayer
var enabled := false
func _ready() -> void:
 ambience = AudioStreamPlayer.new()
 ambience.stream = WATER
 ambience.volume_db = -22
 add_child(ambience)
 ambience.finished.connect(func():
  if enabled:
   ambience.play())
 effect = AudioStreamPlayer.new()
 effect.volume_db = -12
 add_child(effect)
func set_enabled(value: bool) -> void:
 enabled = value
 if enabled and not ambience.playing:
  ambience.play()
 elif not enabled:
  ambience.stop()
  effect.stop()
func play(action: String) -> void:
 if enabled:
  effect.stream = CAST if action == "cast" else REEL
  effect.play()
