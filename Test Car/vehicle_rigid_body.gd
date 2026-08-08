class_name AdvancedArcadeCar extends RigidBody3D

@export_group("Suspension Springs")
@export var spring_strength: float = 350.0   
@export var spring_damping: float = 25.0    
@export var spring_length: float = 1.0      

@export_group("Engine & Speed")
@export var max_engine_force: float = 185.0
@export var base_steering_speed: float = 3.5  # Lowered and converted to exact radians/sec
@export var grip: float = 18.0              
@export var drift_grip: float = 1.8         

@export_group("Nodes")
@export var front_left_ray: RayCast3D
@export var front_right_ray: RayCast3D
@export var back_left_ray: RayCast3D
@export var back_right_ray: RayCast3D

@onready var wheels = [front_left_ray, front_right_ray, back_left_ray, back_right_ray]

var throttle_input := 0.0
var rotate_input := 0.0

func _ready() -> void:
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.friction = 0.0
	
	# Enforce an explicit physical dampening lock
	linear_damp = 0.2
	angular_damp = 6.0

func _physics_process(delta: float) -> void:
	throttle_input = Input.get_axis("Backward", "Forward")
	rotate_input = Input.get_axis("Right", "Left")
	
	var grounded_wheels_count := 0
	
	# 1. HANDLE 4-POINT HOOKE'S LAW SUSPENSION
	for ray in wheels:
		if ray and ray.is_colliding():
			grounded_wheels_count += 1
			var collision_point = ray.get_collision_point()
			
			var current_length = global_position.distance_to(collision_point)
			var compression = spring_length - current_length
			
			var upward_speed = global_transform.basis.y.dot(linear_velocity)
			var suspension_force = (compression * spring_strength) - (upward_speed * spring_damping)
			
			var force_vector = global_transform.basis.y * max(0.0, suspension_force)
			apply_force(force_vector, ray.global_position - global_position)

	# 2. RUN GROUNDED HANDLING LOGIC
	if grounded_wheels_count >= 2:
		# Apply Forward/Backward Engine Central Force
		apply_central_force(global_transform.basis.z * throttle_input * max_engine_force)
		
		# Find out how fast the car is moving forward
		var forward_speed = global_transform.basis.z.dot(linear_velocity)
		var speed_factor = clamp(abs(forward_speed) / 12.0, 0.0, 1.0)
		
		# --- AUTOMATIC TURN-TO-DRIFT SLIDE LOOP ---
		var current_right = global_transform.basis.x
		var sideways_velocity = current_right * linear_velocity.dot(current_right)
		
		var is_turning_hard = abs(rotate_input) > 0.3
		var active_grip = drift_grip if is_turning_hard else grip
		
		# Apply side-friction force directly
		apply_central_force(-sideways_velocity * active_grip * mass)
		
		# --- DIRECT ANGULAR VELOCITY CONTROL (NO MORE MASSIVE SPINNING) ---
		# Instead of apply_torque(), we directly inject a controlled angular velocity.
		# This completely guarantees the car cannot exceed your baseline speed limit.
		if abs(rotate_input) > 0.05:
			var direction_multiplier = sign(forward_speed) if abs(forward_speed) > 0.5 else 1.0
			var drift_multiplier = 1.3 if is_turning_hard else 1.0
			
			var target_spin_y = rotate_input * base_steering_speed * speed_factor * drift_multiplier * direction_multiplier
			
			# Smoothly blend the current rotation speed into our locked target speed
			angular_velocity.y = lerp(angular_velocity.y, target_spin_y, 10.0 * delta)
		else:
			# If you let go of the keys, instantly stabilize the spin axis to zero
			angular_velocity.y = move_toward(angular_velocity.y, 0.0, 12.0 * delta)
