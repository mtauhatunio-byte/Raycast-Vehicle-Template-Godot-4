class_name RayCastWheel3D extends RayCast3D

@export_group("Wheel Properties")
@export var spring_strength: float = 5000.0
@export var spring_damping: float = 120.0
@export var rest_dist: float = 0.5 
@export var wheel_radius: float = 0.4
@export var over_extend: float = 0.2
@export var z_traction: float = 0.01

@export_group("Motor")
@export var use_as_traction: bool = false
@export var use_as_steering: bool = false

@export_group("Nodes")
@export var mesh: MeshInstance3D

@export_group("Curves")
@export var grip_curve: Curve

@export_group("Debug")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var enable_debug: bool = false
@export_subgroup("Debug Rays")
@export var show_accel_rays: bool = false
@export var show_steer_rays: bool = false

var engine_force: float = 0
var grip_factor: float = 0

func _ready() -> void:
	target_position.y = -(rest_dist + wheel_radius + over_extend)


func simulate_wheels(car: RayCastCar) -> void:
#region Misc AKA IDK
	force_raycast_update()
	target_position.y = -(rest_dist + wheel_radius + over_extend)
	
	var forward: Vector3 = -global_basis.z
	var vel: float = forward.dot(car.linear_velocity)
	
	mesh.rotate_x(-vel * get_physics_process_delta_time() / wheel_radius)
	
	if not is_colliding(): return
	
	var contact: Vector3 = get_collision_point()
	var spring_length: float = global_position.distance_to(contact) - wheel_radius
	var offset: float = rest_dist - spring_length
	
	mesh.position.y = move_toward(mesh.position.y, -spring_length, 5.0 * get_process_delta_time())
	contact = mesh.global_position
	var force_pos: Vector3 = contact - car.global_position
#endregion


#region Suspension
	var spring_force: float = spring_strength * offset
	var tire_vel: Vector3 = car.get_point_velocity(contact)
	var spring_damp_f: float = spring_damping * global_basis.y.dot(tire_vel)
	
	var y_force: Vector3 = (spring_force - spring_damp_f) * get_collision_normal()
#endregion


#region Acceleration
	if use_as_traction and car.motor_input:
		var speed_ratio: float = vel / car.max_speed
		var ac: float = car.accel_curve.sample_baked(speed_ratio)
		var accel_force: Vector3 = forward * car.acceleration * car.motor_input * ac
		car.apply_force(accel_force, force_pos)
		if show_accel_rays: DebugDraw3D.draw_arrow_ray(contact, accel_force/car.mass, 1.0, Color.RED, 0.01)
#endregion


#region Steering
	var steering_x_vel: float = global_basis.x.dot(tire_vel)
	
	grip_factor = absf(steering_x_vel / tire_vel.length())
	var x_traction: float = grip_curve.sample_baked(grip_factor)
	
	if not car.handbreak and grip_factor < 0.2:
		car.slipping = false
	if car.handbreak:
		x_traction = 0.01
	elif car.slipping:
		x_traction = 0.1
	
	var gravity: float = -car.get_gravity().y
	var x_force: Vector3 = -global_basis.x * steering_x_vel * x_traction * ((car.mass * gravity) / car.wheels.size())
	
	var f_vel: float = forward.dot(tire_vel)
	var z_friction: float = z_traction
	var z_force: Vector3 = global_basis.z * f_vel * z_friction * ((car.mass * gravity) / car.wheels.size())
	
	car.apply_force(x_force, force_pos)
	car.apply_force(y_force, force_pos)
	car.apply_force(z_force, force_pos)
	
	if show_steer_rays: 
		DebugDraw3D.draw_arrow_ray(contact, x_force/car.mass, 1, Color.GREEN, 0.01)
		DebugDraw3D.draw_arrow_ray(contact, y_force/car.mass, 1, Color.BLUE, 0.01)
#endregion
