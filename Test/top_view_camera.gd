class_name TopDownDebugCamera extends Camera3D

@export var height: float = 10.0
@export var target: Node3D = null

func _process(delta: float) -> void:
	global_position = Vector3(
		target.global_position.x,
		target.global_position.y + height,
		target.global_position.z,
	)
