extends Node

var shake_strength: float = 0.0
var shake_fade: float = 5.0

# Max structural limits for the camera to read
var max_shake_offset := Vector3(0.5, 0.5, 0.0)
var max_shake_roll: float = 0.1

func _process(delta: float) -> void:
	if shake_strength > 0.0:
		# move_toward guarantees it hits EXACTLY 0.0 so the math cleanly stops
		shake_strength = move_toward(shake_strength, 0.0, shake_fade * delta)

# Call this function from any script in your game to trigger a shake
func add_shake(amount: float, fade_speed: float = 5.0) -> void:
	shake_strength = clamp(shake_strength + amount, 0.0, 1.0)
	shake_fade = fade_speed
