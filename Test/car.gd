class_name RayCastCar extends RigidBody3D

#region @export Variables
@export_group("Wheels")
@export var wheels: Array[RayCastWheel3D] = []
@export var wheel_fl: RayCastWheel3D
@export var wheel_fr: RayCastWheel3D
@export var wheel_bl: RayCastWheel3D
@export var wheel_br: RayCastWheel3D

@export_group("Engine")
@export var acceleration: float = 300.0
@export var max_speed: float = 20.0
@export var use_projected_force: bool = true
@export var accel_curve: Curve

@export_group("Physics")
@export var mass_center: float

@export_group("Steering")
@export_subgroup("Turning")
@export var tire_turn_speed: float = 2.0
@export var tire_turn_max_degress: float = 25.0

@export_group("Skid Marks")
@export var skid_marks: Array[CPUParticles3D] = []

@export_group("Debug")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var enable_debug: bool = false
@export var show_speed_ray: bool = false
#endregion


#region Member Variables
var motor_input: float = 0
var turn_input: float = 0
var speed: float = 0.0
var grounded: bool = false
var braking: bool = false
var handbreak: bool = false
var slipping: bool = false
var sideways_velocity: float = 0.0
#endregion


func _unhandled_input(event: InputEvent) -> void:
	
	if event.is_action_pressed("Handbrake"):
		handbreak = true
		slipping = true
	elif event.is_action_released("Handbrake"):
		handbreak = false
	
	if event.is_action_pressed("Forward"):
		motor_input = 1
	elif event.is_action_released("Forward"):
		motor_input = 0
	
	if event.is_action_pressed("Backward"):
		motor_input = -1
	elif event.is_action_released("Backward"):
		motor_input = 0


func _physics_process(delta: float) -> void:
	if show_speed_ray:
		DebugDraw3D.draw_arrow_ray(global_position + Vector3(0, 1, 0), linear_velocity, 1.0, Color.PINK, 0.1)
	
	grounded = false
	var id: int = 0
	
	for wheel in wheels: 
		if wheel.is_colliding(): grounded = true
		wheel.simulate_wheels(self)
		wheel_rotation(wheel, delta)
		
		skid_marks[id].global_position = wheel.get_collision_point() + Vector3.UP * 0.01
		skid_marks[id].look_at(skid_marks[id].global_position + global_basis.z)
		
		if not handbreak and wheel.grip_factor < 0.2:
			slipping = false
			skid_marks[id].emitting = false
			
		if handbreak and not skid_marks[id].emitting:
			skid_marks[id].emitting = true
			
		if wheel.is_colliding():
			grounded = true
		
		id += 1
		
		
	
	speed = linear_velocity.length()


func wheel_rotation(wheel: RayCastWheel3D, delta: float) -> void:
	if not wheel.use_as_steering: return
	
	turn_input = Input.get_axis("Right", "Left")
	if turn_input:
		wheel.rotation.y = clampf(
			wheel.rotation.y + turn_input * delta,
			deg_to_rad(-tire_turn_max_degress),
			deg_to_rad(+tire_turn_max_degress),
		)
		
	else:
		wheel.rotation.y = move_toward(
			wheel.rotation.y,
			0,
			tire_turn_speed * delta
		)


func get_point_velocity(point: Vector3) -> Vector3:
	return linear_velocity + angular_velocity.cross(point - global_position)


func get_sideways_velocity() -> float:
	return -global_basis.x.dot(linear_velocity)
