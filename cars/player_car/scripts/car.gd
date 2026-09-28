extends RigidBody3D

@export var wheels : Array[RayCast3D] = []

@export var spring_strength : float = 1500.0
@export var spring_damping : float = 55.0
@export var rest_distance : float = 0.6
@export var wheel_radius : float = 0.4
@export var over_extend : float = 0.2

func _ready() -> void:
	var health : float = get("angular_damp")
	print(health)

func _physics_process(delta: float) -> void:
	for wheel in wheels:
		wheel_suspension(wheel)
	
	if Input.is_action_just_pressed("Switch"):
		apply_central_impulse(Vector3.UP * 500)



func wheel_suspension(ray : RayCast3D) -> void:
	if ray.is_colliding():
		ray.target_position.y = -(rest_distance + wheel_radius + over_extend)
		
		var contact : Vector3 = ray.get_collision_point()
		var spring_up_dir : Vector3 = ray.global_transform.basis.y
		var spring_length : float = ray.global_position.distance_to(contact) - wheel_radius
		var offset : float = rest_distance - spring_length
		
		ray.get_node("Mesh").position.y = -spring_length
		
		var spring_force : float = spring_strength * offset
		
		var world_vel : Vector3 = get_point_velocity(contact)
		var relative_vel : float = spring_up_dir.dot(world_vel)
		var spring_damp_force : float = spring_damping * relative_vel
		
		var force_vector : Vector3 = (spring_force - spring_damp_force) * spring_up_dir
		
		var force_pos_offset : Vector3 = contact - global_position
		apply_force(force_vector, force_pos_offset)


func get_point_velocity(point : Vector3) -> Vector3:
	return linear_velocity + angular_velocity.cross(point - global_position)
