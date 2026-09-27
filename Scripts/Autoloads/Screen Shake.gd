extends Node

var current_scene: int = 1

var shake_strength: float = 0.0
var shake_fade: float = 5.0

const ball_scene: PackedScene = preload("res://Scenes/Test/test.tscn")
const suspension_scene: PackedScene = preload("res://Scenes/Test/suspension_test.tscn")

# Max structural limits for the camera to read
var max_shake_offset := Vector3(0.5, 0.5, 0.0)
var max_shake_roll: float = 0.1

func _process(delta: float) -> void:
	if shake_strength > 0.0:
		# move_toward guarantees it hits EXACTLY 0.0 so the math cleanly stops
		shake_strength = move_toward(shake_strength, 0.0, shake_fade * delta)
		
		
	if Input.is_action_just_pressed("Switch"):
		if current_scene == 1:
			current_scene = 2
		elif current_scene == 2:
			current_scene = 1
		
		match current_scene:
			1: 
				get_tree().change_scene_to_packed(ball_scene)
			2:
				get_tree().change_scene_to_packed(suspension_scene)
			_:
				pass
				


# Call this function from any script in your game to trigger a shake
func add_shake(amount: float, fade_speed: float = 5.0) -> void:
	shake_strength = clamp(shake_strength + amount, 0.0, 1.0)
	shake_fade = fade_speed
	
