class_name RayCastCar extends RigidBody3D

#region @export Variables
@export_group("Arrays")
@export var wheels : Array[RaycastWheel] = []
@export var skid_marks : Array[CPUParticles3D] = []

@export_group("Engine")
@export var acceleration : float = 600.0
@export var max_speed : float = 20.0
@export var accel_curve : Curve = null

@export_group("Steering")
@export var tire_turn_speed : float = 2.0
@export var tire_max_turn_degrees : float = 25.0

@export_group("Debug")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var debug : bool = false
@export var show_velocity_ray : bool = false
#endregion


#region @onready Variables
@onready var total_wheels : int = wheels.size()
#endregion


#region Member Variables
var motor_input : float = 0
var turn_input : float = 0.0
var handbrake : bool = false
var slipping : bool = false
var grounded : bool = false
#endregion


func _ready() -> void:
	calculate_center_of_mass(false)


func calculate_center_of_mass(calculate : bool) -> void:
	if not calculate: return
	
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_AUTO
	
	var auto_com : Vector3 = center_of_mass
	
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	
	center_of_mass = Vector3(auto_com.x, -0.3, auto_com.z)


func get_point_velocity(point : Vector3) -> Vector3:
	var speed : Vector3 = linear_velocity
	var angular : Vector3 = angular_velocity
	var center : Vector3 = to_global(center_of_mass)
	var cross : Vector3 = angular.cross(point - center)
	var return_value : Vector3 = speed + cross
	
	return return_value


func _unhandled_input(event : InputEvent) -> void:
	if event.is_action_pressed("Handbrake"):
		handbrake = true
		slipping = true
	elif event.is_action_released("Handbrake"):
		handbrake = false
		
	
	if event.is_action_pressed("Forward"):
		motor_input = 1.0
	elif event.is_action_released("Forward"):
		motor_input = 0.0
	
	
	if event.is_action_pressed("Backward"):
		motor_input = -1.0
	elif event.is_action_released("Backward"):
		motor_input = 0.0
		
	turn_input = Input.get_axis("Right", "Left")


func wheel_rotation(wheel : RaycastWheel, delta : float) -> void: 
	if not wheel.use_as_steering: return
	
	if turn_input != 0.0:
		wheel.rotation.y = clampf(
			wheel.rotation.y + turn_input * delta,
			deg_to_rad(-tire_max_turn_degrees),
			deg_to_rad(+tire_max_turn_degrees),
		)
	else:
		wheel.rotation.y = move_toward(
			wheel.rotation.y,
			0.0,
			tire_turn_speed * delta
		)


func _physics_process(delta : float) -> void:
	# Keep track of the wheel index so we map each wheel to its own separate skid mark
	for i: int in range(wheels.size()):
		var wheel: RaycastWheel = wheels[i]
		wheel.simulate_wheels()
		
		# Only update drift marks if the wheel is actually touching the ground
		if wheel.is_colliding():
			drift_marks(wheel, i)
		else:
			# Safety turn-off if airborne
			if i < skid_marks.size():
				skid_marks[i].emitting = false
				
		check_ground_collision(wheel)
		wheel_rotation(wheel, delta)
		
		if Input.is_action_just_pressed("Change"):
			wheel.use_responsive_steering = !wheel.use_responsive_steering


func drift_marks(wheel : RaycastWheel, id : int) -> void:
	# Out of bounds check to prevent runtime crashes
	if id >= skid_marks.size(): return
	
	var mark : CPUParticles3D = skid_marks[id]
	
	# IMPORTANT: Go to your CPUParticles3D settings in the Godot Inspector!
	# Ensure "Disable Collision" is checked under the particle properties.
	
	mark.global_position = wheel.get_collision_point() + Vector3.UP * 0.02
	
	# Safe guard look_at to ensure it isn't completely vertical or pointing at zero length vectors
	var look_target: Vector3 = mark.global_position + get_forward()
	if not mark.global_position.is_equal_approx(look_target):
		mark.look_at(look_target)
	
	# Simplified drift emission control logic
	if handbrake or wheel.grip_factor > 0.6: # Tweak threshold based on your wheel logic
		mark.emitting = true
	else:
		mark.emitting = false


func check_ground_collision(wheel : RaycastWheel) -> void:
	if wheel.is_colliding():
		grounded = true


func get_forward() -> Vector3:
	return -global_basis.z


func get_right() -> Vector3:
	return global_basis.x


func get_forward_velocity() -> float:
	return get_forward().dot(linear_velocity)


func get_right_velocity() -> float:
	return get_right().dot(linear_velocity)


func debug_arrows() -> void:
	if debug and OS.is_debug_build():
		if show_velocity_ray:
			DebugDraw3D.draw_arrow_ray(global_position, linear_velocity, 10, Color.ORANGE)
