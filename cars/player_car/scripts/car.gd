extends RigidBody3D

@export var wheels : Array[RayCast3D] = []

@export var spring_strength : float = 5000.0
@export var spring_damping : float = 120.0
@export var rest_distance : float = 0.5


func wheel_suspension(ray : RayCast3D) -> void:
	pass


func _physics_process(delta: float) -> void:
	for wheel in wheels:
		wheel_suspension(wheels[wheel])
