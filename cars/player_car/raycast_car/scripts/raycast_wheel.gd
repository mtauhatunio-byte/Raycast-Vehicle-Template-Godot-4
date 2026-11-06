class_name RayCastWheel extends RayCast3D

@export_group("Spring")
@export var spring_strength : float = 1500.0
@export var spring_damping : float = 55.0
@export var rest_distance : float = 0.4
@export var wheel_radius : float = 0.4
@export var over_extend : float = 0.2
@export var max_spring_force : float = INF
@export var grip_curve : Curve = null
@export var z_traction : float = 0.05
@export var brake_traction : float = 0.25
@export var shapecast_offset : float = 0.3
@export var slip_exit_threshold : float = 0.3

@export_group("Usage", "use_as_")
@export var use_as_suspension : bool = true
@export var use_as_traction : bool = false
@export var use_as_steering : bool = false
@export var use_as_friction : bool = true
@export var use_as_projected_force : bool = false

@export_group("Debug")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var debug : bool = false
@export_subgroup("Rays")
@export var show_acceleration_ray : bool = false
@export var show_steering_ray : bool = false
@export var show_suspension_ray : bool = false
@export var show_friction_ray : bool = false
@export var ray_length : float = 1.0
@export var arrow_size : float = 0.05

@onready var mesh = get_child(0) as MeshInstance3D
@onready var shapecast = get_child(2) as ShapeCast3D
@onready var car = get_owner() as RayCastCar

var engine_force : float = 0.0
var grip_factor : float = 0.0
var braking : bool = false


func _ready() -> void:
	target_position.y = -(rest_distance + over_extend + wheel_radius)
	
	if shapecast:
		shapecast.target_position.x = -(rest_distance + over_extend) - shapecast_offset
		shapecast.add_exception(get_parent())
		shapecast.position.y = shapecast_offset


func simulate_wheels(dt : float) -> void:
	target_position.y = -(rest_distance + over_extend + wheel_radius)
	if shapecast:
		shapecast.target_position.x = -(rest_distance + over_extend) - shapecast_offset
	
	var forward : Vector3 = -global_basis.z.normalized()
	var vel : float = forward.dot(car.linear_velocity)
	mesh.rotate_x( (-vel * get_physics_process_delta_time() ) / wheel_radius)
	
	if not shapecast and not is_colliding() : return
	if shapecast and not shapecast.is_colliding() : return
	
	var contact : Vector3 = shapecast.get_collision_point(0) if shapecast else get_collision_point()
	var spring_length : float = maxf(0.0, global_position.distance_to(contact)) - wheel_radius
	var offset : float = rest_distance - spring_length
	
	mesh.position.y = -spring_length
	contact = mesh.global_position
	
	var force_pos : Vector3 = contact - car.global_position
	
	var spring_force : float = spring_strength * offset
	var tire_vel : Vector3 = car.get_point_velocity(contact)
	var spring_damp_f : float = spring_damping * global_basis.y.dot(tire_vel)
	var suspension_force : float = clampf(spring_force - spring_damp_f, -max_spring_force, max_spring_force)
	
	var y_force : Vector3 = suspension_force * get_collision_normal()
	if shapecast:
		y_force = suspension_force * shapecast.get_collision_normal(0)
	
	var w_force : Vector3 = Vector3.ZERO
	
	if car.throttle and use_as_traction:
		var speed_ratio : float = vel / car.max_speed
		var ac : float = car.acceleration_curve.sample_baked(speed_ratio)
		
		var force_per_wheel : float = (car.acceleration * car.mass) / car.wheels.size()
		
		w_force = ac * force_per_wheel * forward * car.throttle
		car.apply_force(w_force, force_pos)
	
	var steering_x_vel : float = global_basis.x.dot(tire_vel)
	
	grip_factor = absf(steering_x_vel / tire_vel.length())
	if absf(vel) < 0.2:
		grip_factor = 0.0
	var x_traction : float = grip_curve.sample_baked(grip_factor)
	
	if use_as_traction:
		if not car.handbreak and grip_factor < slip_exit_threshold:
			car.slipping = false
		if car.handbreak:
			x_traction = 0.01
		elif car.slipping:
			x_traction = 0.1
	
	var gravity : float = -car.get_gravity().y
	var x_force : Vector3 = (
		-global_basis.x 
		* steering_x_vel 
		* x_traction 
		* ((car.mass * gravity) / car.wheels.size()))
	
	var f_vel : float = forward.dot(tire_vel)
	var z_friction : float = brake_traction if braking else z_traction
	if absf(f_vel) < 0.1:
		z_friction = 2.0
	var z_force : Vector3 = -forward * f_vel * z_friction * ((car.mass * gravity) / car.wheels.size())
	
	if absf(f_vel) < 0.1:
		var susp : Vector3 = global_basis.y * suspension_force
		z_force.z -= susp.z * car.global_basis.y.dot(Vector3.UP)
		x_force.x -= susp.x * car.global_basis.y.dot(Vector3.UP)
	
	car.apply_force(x_force, force_pos)
	car.apply_force(y_force, force_pos)
	car.apply_force(z_force, force_pos)
	
	if OS.is_debug_build() and debug:
		if show_acceleration_ray:
			DebugDraw3D.draw_arrow_ray(contact, w_force/car.mass, ray_length, Color.RED, arrow_size)
		if show_steering_ray:
			DebugDraw3D.draw_arrow_ray(contact, x_force/car.mass, ray_length, Color.BLUE, arrow_size)
		if show_suspension_ray:
			DebugDraw3D.draw_arrow_ray(contact, y_force/car.mass, ray_length, Color.GREEN, arrow_size)
		if show_friction_ray:
			DebugDraw3D.draw_arrow_ray(contact, z_force/car.mass, ray_length, Color.YELLOW, arrow_size)
