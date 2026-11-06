class_name RayCastCar extends RigidBody3D

@export var wheels : Array[RayCastWheel] = []

@export var acceleration : float = 600.0
@export var max_speed : float = 20.0
@export var acceleration_curve : Curve = null

@export var tire_turn_speed : float = 2.0
@export var tire_turn_max_degress : float = 25.0

@export_group("Debug")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var debug : bool = false
@export var show_speed_ray : bool = false
@export var show_center_of_mass : bool = false


var dt : float = 0.0

var motor : float = 0.0
var turn : float = 0.0
var grounded : bool = false
var handbreak : bool = false
var slipping : bool = false


func _ready() -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("accelerate"):
		motor = 1.0
	elif event.is_action_released("accelerate"):
		motor = 0.0
		
	if event.is_action_pressed("decelerate"):
		motor = -1.0
	elif event.is_action_released("decelerate"):
		motor = 0.0
	
	
	if event.is_action_pressed("handbrake"):
		handbreak = true
		slipping = true
	elif event.is_action_released("handbrake"):
		handbreak = false


func _physics_process(delta: float) -> void:
	grounded = false
	dt = delta
	
	for wheel : RayCastWheel in wheels:
		wheel.simulate_wheels(dt)
		wheel_rotation(wheel)
		if wheel.is_colliding():
			grounded = true
		if Input.is_action_pressed("brake"):
			wheel.braking = true
		else:
			wheel.braking = false
	
	
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
	
	turn = Input.get_axis("steer_right", "steer_left") * tire_turn_speed
	
	if turn:
		wheel.rotation.y = clampf(wheel.rotation.y + turn * dt, deg_to_rad(-tire_turn_max_degress), deg_to_rad(tire_turn_max_degress))
	else:
		wheel.rotation.y = move_toward(wheel.rotation.y, 0.0, tire_turn_speed * dt)



func get_point_velocity(point : Vector3) -> Vector3:
	return linear_velocity + angular_velocity.cross(point - global_position)
