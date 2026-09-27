class_name RaycastWheel extends RayCast3D

@export_group("Wheel Properties")
@export var spring_strength: float = 5000.0
@export var spring_damping : float = 120.0
@export var rest_dist : float = 0.5
@export var over_extend : float = 0.0
@export var wheel_radius : float = 0.4
@export var z_traction : float = 0.05

@export_group("Motor")
@export var use_as_traction : bool = false
@export var use_as_steering : bool = false
@export var use_responsive_steering : bool = false
@export var grip_curve : Curve = null

@export_group("Nodes")
@export var mesh : Node3D = null
@export var car : RayCastCar = null

@export_group("Debug")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var debug : bool = false
@export var show_steer_rays : bool = false
@export var show_accel_rays : bool = false
@export var show_friction_rays : bool = false
@export var show_suspension_rays : bool = false

var engine_force : float = 0.0
var grip_factor : float = 0.0

var forward : Vector3 = Vector3.ZERO
var right : Vector3 = Vector3.ZERO
var speed : float = 0.0
var tire_speed : Vector3 = Vector3.ZERO
var contact: Vector3 = Vector3.ZERO
var delta : float = 0.0
var gravity : float = 0.0

var steer_force : Vector3 = Vector3.ZERO
var acceleration_force : Vector3 = Vector3.ZERO
var suspension_force : Vector3 = Vector3.ZERO
var friction_force : Vector3 = Vector3.ZERO
var force_position : Vector3 = Vector3.ZERO
var steer_force_position : Vector3 = Vector3.ZERO


func _ready() -> void:
	mesh = get_child(0)
	target_position.y = -(rest_dist + wheel_radius + over_extend)
	var tween : Tween = create_tween()
	tween.tween_property(mesh, "position:y", target_position.y + 0.5, 1.0)


func simulate_wheels() -> void:
	force_raycast_update()
	target_position.y = -(rest_dist + wheel_radius + over_extend) 
	
	
	# 1. ALWAYS RESET FORCES FIRST (Stops airborne ghost-force build up)
	suspension_force = Vector3.ZERO
	acceleration_force = Vector3.ZERO
	steer_force = Vector3.ZERO
	friction_force = Vector3.ZERO
	
	# 2. CALCULATE VECTORS FIRST (Must happen before reading them)
	delta = get_physics_process_delta_time()
	forward = -global_basis.z
	right = global_basis.x # Fixed to point Right (Positive X)
	gravity = -car.get_gravity().y
	
	# 3. IF AIRBORNE, SPIN MESH AND EXIT (Do not apply physics forces)
	if not is_colliding():
		speed = forward.dot(car.linear_velocity)
		mesh.rotate_x(-speed * delta)
		#mesh.position.y = move_toward(mesh.position.y, target_position.y + 0.5, 2.0 * delta)
		return
		
	# 4. GROUNDED STAGE (Safe to run physics calculations)
	contact = get_collision_point()
	force_position = contact - car.global_position
	speed = forward.dot(car.linear_velocity)
	steer_force_position = Vector3(force_position.x, car.center_of_mass.y, force_position.z)
	
	mesh.rotate_x(-speed * delta)
	
	# Execute force math sequentially
	apply_suspension()
	apply_acceleration()
	apply_steering()
	apply_friction()
	
	# Apply final integrated safe forces
	apply_forces()
	debug_arrows()


func apply_suspension() -> void:
	# Compute current spring contraction depth
	var spring_length : float = maxf(0.0, global_position.distance_to(contact) - wheel_radius)
	var offset : float = rest_dist - spring_length
	
	# Visual node attachment adjustment
	mesh.position.y = spring_length#move_toward(mesh.position.y, -spring_length, 5.0 * delta)
	
	# Track speed at exact contact patch
	tire_speed = car.get_point_velocity(contact)
	
	# Hooke's Law: Force = (Strength * Compression)
	var spring_force : float = spring_strength * offset
	if offset > (rest_dist * 0.9):
		spring_force *= 2.5
	
	# Damping: project contact patch velocity cleanly against the vertical axis
	var spring_damp: float = spring_damping * basis.y.dot(car.get_point_velocity(global_position))
	
	# Combine forces cleanly along the ground normal vector
	suspension_force = get_collision_normal() * (spring_force - spring_damp)
	
	#var total_power: float = spring_force - spring_damp
	#if total_power < 0.0:
		#total_power = 0.0
		
	#suspension_force = get_collision_normal() * total_power


func apply_acceleration() -> void:
	if not is_colliding(): return
	
	if use_as_traction and car.motor_input:
		var speed_ratio : float = speed / car.max_speed
		var ac : float = car.accel_curve.sample_baked(speed_ratio)
		var accel_force : Vector3 = forward * car.acceleration * car.motor_input * ac
		acceleration_force = accel_force


func apply_steering() -> void:
	var steering_x_speed : float = -right.dot(tire_speed)
	var speed_length : float = tire_speed.length()
	
	if speed_length > 0.001:
		grip_factor = absf(steering_x_speed / speed_length)
	else:
		grip_factor = 0.0
	
	var x_traction : float = grip_curve.sample_baked(grip_factor)
	
	if not car.handbrake and grip_factor < 0.2:
		car.slipping = false
	if car.handbrake:
		x_traction = 0.01
	elif car.slipping:
		x_traction = 0.1
	
	if use_responsive_steering:
		steer_force = (car.get_right() * steering_x_speed * x_traction * ((car.mass * gravity) / car.total_wheels))
	else:
		steer_force = (right * steering_x_speed * x_traction * ((car.mass * gravity) / car.total_wheels))


func apply_friction() -> void:
	var forward_speed : float = forward.dot(tire_speed)
	var z_friction : float = z_traction
	var z_force : Vector3 = -forward * forward_speed * z_friction * ((car.mass * gravity) / car.total_wheels)
	friction_force = z_force
	

func apply_forces() -> void:
	car.apply_force(acceleration_force, force_position)
	car.apply_force(steer_force, force_position)
	car.apply_force(suspension_force, force_position)
	car.apply_force(friction_force, steer_force_position)


func debug_arrows() -> void:
	if not debug and not OS.is_debug_build(): 
		return
	if show_accel_rays:
		DebugDraw3D.draw_arrow_ray(
			contact, 
			acceleration_force/car.mass + Vector3.UP * 1, 
			1, Color.RED, 
			0.1
			)
	if show_steer_rays:
		DebugDraw3D.draw_arrow_ray(
		contact, 
		steer_force/car.mass + Vector3.UP * 1, 
		1, Color.GREEN, 
		0.1
		)
	if show_suspension_rays:
		DebugDraw3D.draw_arrow_ray(
			contact, 
			suspension_force/car.mass + Vector3.UP * 1, 
			1, Color.BLUE, 
			0.1
			)
	if show_friction_rays:
		DebugDraw3D.draw_arrow_ray(
		contact, 
		friction_force/car.mass + Vector3.UP * 1, 
		1, Color.YELLOW, 
		0.1
		)
