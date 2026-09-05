class_name RaycastWheel extends RayCast3D

@export_group("Wheel Properties")
@export var spring_strength: float = 5000.0
@export var max_spring_force: float = INF
@export var spring_damping: float = 120.0
@export var rest_dist: float = 0.5 
@export var wheel_radius: float = 0.4
@export var over_extend: float = 0.2
@export var z_traction: float = 0.01
@export var brake_strength: float = 2.0
@export var shapecast_offset: float = 0.3

@export_group("Motor")
@export var use_as_traction: bool = false
@export var use_as_steering: bool = false

@export_group("Nodes")
@export var mesh: MeshInstance3D
@export var shapecast: ShapeCast3D
@export var car: RaycastCar

@export_group("Curves")
@export var grip_curve: Curve

@export_group("Debug")
@export var enable_debug: bool = false
@export var show_accel_rays: bool = false
@export var show_steer_rays: bool = false

var engine_force: float = 0
var grip_factor: float = 0
var braking: bool = false
var x_traction: float = 0.5
var z_friction: float = 0.01
var steering_angle: float = 0.0

func _ready() -> void:
	# Keep setup logic uniform
	target_position.y = -(rest_dist + wheel_radius + over_extend)
	if shapecast:
		shapecast.target_position.y = -(rest_dist + over_extend) - shapecast_offset
		if car:
			shapecast.add_exception(car)

func simulate_wheels(car_node: RaycastCar) -> void:
	# 1. FIXED: Removed target_position jitter code that was overwriting _ready()
	force_raycast_update()
	if shapecast:
		shapecast.force_shapecast_update()
	
	var forward: Vector3 = -global_basis.z.normalized()
	var vel: float = forward.dot(car_node.linear_velocity)
	
	# Mesh rotation based on actual chassis forward speed
	if mesh:
		mesh.rotate_x(-vel * get_physics_process_delta_time() / wheel_radius)
	
	# Collision check validation
	var has_collision = shapecast.is_colliding() if shapecast else is_colliding()
	if not has_collision: return
	
	# Extract true collision point
	var collision_point: Vector3 = shapecast.get_collision_point(0) if shapecast else get_collision_point()
	var collision_normal: Vector3 = shapecast.get_collision_normal(0) if shapecast else get_collision_normal()
	
	# Calculate suspension length off true point, NOT mesh position
	var spring_length: float = maxf(0.0, global_position.distance_to(collision_point) - wheel_radius)
	var offset: float = rest_dist - spring_length
	
	# Animate the visual mesh smoothly
	if mesh:
		mesh.position.y = move_toward(mesh.position.y, -spring_length, 5.0 * get_physics_process_delta_time())
	
	# FIXED: Physics calculation anchor points should use true collision data, not visual meshes
	var force_pos: Vector3 = collision_point - car_node.global_position

	#region Suspension Physics
	var spring_force: float = spring_strength * offset
	var tire_vel: Vector3 = car_node.get_point_velocity(collision_point)
	var spring_damp_f: float = spring_damping * global_basis.y.dot(tire_vel)
	
	var suspension_force: float = clampf(spring_force - spring_damp_f, -max_spring_force, +max_spring_force)
	var y_force: Vector3 = suspension_force * collision_normal
	#endregion

	#region Acceleration
	if use_as_traction and car_node.motor_input:
		var speed_ratio: float = vel / car_node.max_speed
		var ac: float = car_node.accel_curve.sample_baked(speed_ratio)
		var accel_force: Vector3 = forward * car_node.acceleration * car_node.motor_input * ac
		car_node.apply_force(accel_force, force_pos)
		
		if show_accel_rays and enable_debug: 
			DebugDraw3D.draw_arrow_ray(collision_point, accel_force / car_node.mass, 1.0, Color.RED, 0.01)
	#endregion

	#region Steering & Friction Matrix
	var wheel_basis: Basis = global_basis
	if use_as_steering:
		wheel_basis = global_basis.rotated(global_basis.y, steering_angle)

	var steering_x_vel: float = wheel_basis.x.dot(tire_vel)
	var current_vel_len: float = tire_vel.length()
	
	if current_vel_len > 0.01:
		grip_factor = absf(steering_x_vel / current_vel_len)
	else:
		grip_factor = 0.0
		
	if absf(vel) < 0.2:
		grip_factor = 0.0
		
	var target_traction: float = grip_curve.sample_baked(grip_factor)
	
	# Drift State Modifications
	if use_as_traction:
		if not car_node.handbreak and grip_factor < 0.45:
			car_node.slipping = false
		
		if car_node.handbreak:
			target_traction = 0.1
		elif car_node.slipping:
			target_traction = 0.65
			
			# FIXED: Removed delta time multiplication here. Rigidbody forces handle delta internally.
			var drift_brake: float = 0.4 
			var drag_force: Vector3 = -global_basis.x * steering_x_vel * car_node.mass * drift_brake
			car_node.apply_central_force(drag_force)
	
	x_traction = lerpf(x_traction, target_traction, 12.0 * get_physics_process_delta_time())
	
	var gravity: float = -car_node.get_gravity().y
	var x_force: Vector3 = -wheel_basis.x * steering_x_vel * x_traction * ((car_node.mass * gravity) / car_node.wheels.size())

	# Forward friction matrix (Z Force)
	var f_vel: float = forward.dot(tire_vel)
	var target_z_friction: float = z_traction
	
	if absf(f_vel) < 0.1:
		target_z_friction = 2.0
	elif braking: 
		target_z_friction = brake_strength
	elif car_node.slipping and use_as_traction:
		target_z_friction = z_traction * 0.5
	
	z_friction = lerpf(z_friction, target_z_friction, 12.0 * get_physics_process_delta_time())
	var z_force: Vector3 = wheel_basis.z * f_vel * z_friction * ((car_node.mass * gravity) / car_node.wheels.size())
	
	# Low speed hill holding override
	if absf(f_vel) < 0.1 and not car_node.motor_input and not car_node.slipping:
		var susp: Vector3 = wheel_basis.y * suspension_force
		var down_alignment: float = car_node.global_basis.y.dot(Vector3.UP)
		z_force.z = susp.z * down_alignment
		x_force.x = susp.z * down_alignment
		if car_node.motor_input == 0.0:
			car_node.slipping = false

	# Clamping thresholds
	var max_force_clamp: float = (car_node.mass * gravity) / car_node.wheels.size() * 3.0
	x_force = x_force.limit_length(max_force_clamp)
	z_force = z_force.limit_length(max_force_clamp)
	
	# Apply final physics vectors
	
	car_node.apply_force(x_force, force_pos)
	car_node.apply_force(y_force, force_pos)
	car_node.apply_force(z_force, force_pos)
	
	if show_steer_rays and enable_debug and OS.is_debug_build(): 
		DebugDraw3D.draw_arrow_ray(collision_point, x_force / car_node.mass, 1, Color.GREEN, 0.01)
		DebugDraw3D.draw_arrow_ray(collision_point, y_force / car_node.mass, 1, Color.BLUE, 0.01)
	#endregion
