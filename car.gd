class_name PlayerCar3DV4 extends RigidBody3D

@export_group("Suspension")
@export var suspension_rest_length: float = 1.3
@export var spring_strength: float = 275.0
@export var spring_damping: float = 28.0

@export_group("Arcade Handling")
@export var forward_speed_limit: float = 50.0
@export var grip_factor: float = 0.85       
@export var drift_grip_factor: float = 0.12 

@export_group("Engine")
@export var acceleration: float = 45.0
@export var steering: float = 21.0
@export var turn_stop_limit: float = 0.75
@export var brake_strength: float = 3.0

enum MODES {FORWARD = 1, BACKWARD = -1, NULL = 0, DEAD = 2}
var mode: MODES = MODES.FORWARD

var engine_force := 0.0
var rotate_input := 0.0

@export_group("Nodes")
@export var rays: Array[RayCast3D] = []


func _ready() -> void:
	#var suspension_container = get_node_or_null("SuspensionRays")
	#if suspension_container:
		#for child in suspension_container.get_children():
			#if child is RayCast3D:
				#rays.append(child)
				
	if not physics_material_override:
		physics_material_override = PhysicsMaterial.new()
	physics_material_override.friction = 0.0
	physics_material_override.bounce = 0.0
	
	
	print(rays)

func _physics_process(delta: float) -> void:
	#if mode == MODES.DEAD: return
	
	input_processing(delta)

	var is_grounded := false
	for ray in rays:
		if ray.is_colliding():
			is_grounded = true
			var collision_point = ray.get_collision_point()
			var current_length = ray.global_position.distance_to(collision_point)
			var compression = suspension_rest_length - current_length
			
			var wheel_velocity = get_point_velocity(ray.global_position)
			var upward_vel = ray.global_transform.basis.y.dot(wheel_velocity)
			
			var spring_force_magnitude = (compression * spring_strength) - (upward_vel * spring_damping)
			var final_spring_force = ray.global_transform.basis.y * spring_force_magnitude
			apply_force(final_spring_force, ray.global_position - global_position)

	if is_grounded:
		var current_velocity = linear_velocity
		var forward_velocity = global_transform.basis.z.dot(current_velocity)
		var sideways_velocity = global_transform.basis.x.dot(current_velocity)
		
		if abs(forward_velocity) < forward_speed_limit:
			apply_central_force(global_transform.basis.z * engine_force)
			
		var active_grip = grip_factor
		if Input.is_action_pressed("Handbrake"):
			active_grip = drift_grip_factor
			
		var lateral_friction_force = -global_transform.basis.x * (sideways_velocity * active_grip / delta)
		apply_central_force(lateral_friction_force)

		if abs(forward_velocity) > turn_stop_limit:
			var steering_direction = -1.0 if forward_velocity < 0 else 1.0
			rotate_y(rotate_input * steering_direction * delta)

func input_processing(delta: float) -> void:
	if Input.is_action_pressed("Forward"):
		mode = MODES.FORWARD
	elif Input.is_action_pressed("Backward"):
		mode = MODES.BACKWARD
	else:
		mode = MODES.NULL
		
	if mode == MODES.FORWARD:
		engine_force = move_toward(engine_force, forward_speed_limit * 10.0, acceleration * 10.0 * delta)
	elif mode == MODES.BACKWARD:
		engine_force = move_toward(engine_force, -forward_speed_limit * 5.0, acceleration * 10.0 * delta)
	else:
		engine_force = move_toward(engine_force, 0.0, acceleration * 15.0 * delta)
		
	if Input.is_action_pressed("Handbrake"):
		linear_damp = brake_strength
	else:
		linear_damp = 0.1 

	rotate_input = 0.0
	rotate_input += Input.get_action_strength("Left")
	rotate_input -= Input.get_action_strength("Right")
	rotate_input *= deg_to_rad(steering)

func get_point_velocity(point_global_position: Vector3) -> Vector3:
	var relative_offset = point_global_position - global_transform.origin
	return linear_velocity + angular_velocity.cross(relative_offset)
