extends Node3D


# Called when the node enters the scene tree for the first time.
func _input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_R):
		get_tree().reload_current_scene()
