class_name RayCastCar extends RigidBody3D

@export var wheels : Array[RayCastWheel] = []

@export var acceleration : float = 600.0
@export var max_speed : float = 20.0
@export var acceleration_curve : Curve = null

@export var tire_turn_speed : float = 2.0
@export var tire_turn_max_degress : float = 25.0
@export var tire_turn_curve_degrees : Curve = null

@export var base_axle_width : float = 1.5

@export_group("Debug")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var debug : bool = false
@export var show_speed_ray : bool = false
@export var show_center_of_mass : bool = false


var dt : float = 0.0

var throttle : float = 0.0
var target_throttle : float = 0.0
var steer_input : float = 0.0
var grounded : bool = false
var handbreak : bool = false
var slipping : bool = false
var braking : bool = false
var forward_speed : float = 0.0

func _physics_process(delta: float) -> void:
	forward_speed = -global_basis.z.dot(linear_velocity)
	grounded = false
	dt = delta
	
	for wheel : RayCastWheel in wheels:
		wheel.simulate_wheels(dt)
		wheel_rotation(wheel)
		if wheel.is_colliding():
			grounded = true
		wheel.braking = braking
	
	
	if grounded:
		center_of_mass = Vector3.ZERO
		linear_damp = 0.0
		physics_material_override.friction = 0.0
	else:
		center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
		center_of_mass = Vector3.DOWN * 0.5
		linear_damp = 0.1
		physics_material_override.friction = 1
	
	
	if OS.is_debug_build() and debug:
		var scope : DebugDraw3DScopeConfig = DebugDraw3D.new_scoped_config().set_no_depth_test(true)
		if show_center_of_mass:
			DebugDraw3D.draw_sphere(to_global(center_of_mass), 0.1, Color.PURPLE)
		if show_speed_ray:
			DebugDraw3D.draw_arrow_ray(global_position, linear_velocity, 1.0, Color.PINK, 0.1)

func wheel_rotation(wheel : RayCastWheel) -> void:
	if not wheel.use_as_steering : return
	
	if tire_turn_curve_degrees:
		tire_turn_max_degress = tire_turn_curve_degrees.sample_baked(forward_speed)
	
	if steer_input:
		wheel.rotation.y = clampf(
			wheel.rotation.y + steer_input * tire_turn_speed * dt, 
			deg_to_rad(-tire_turn_max_degress), 
			deg_to_rad(tire_turn_max_degress)
			)
	else:
		wheel.rotation.y = move_toward(wheel.rotation.y, 0.0, tire_turn_speed * dt)

func _process(delta: float) -> void:
	throttle = move_toward(throttle, target_throttle, delta)

func get_point_velocity(point : Vector3) -> Vector3:
	return linear_velocity + angular_velocity.cross(point - to_global(center_of_mass))
