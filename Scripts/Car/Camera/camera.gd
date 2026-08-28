class_name PlayerCamera3D extends Camera3D

@export var car_mesh: MeshInstance3D 
@export var ball: RigidBody3D 

@export var distance := 4.0
@export var height := 2.0

@export var follow_speed := 8.0

@export var base_fov := 70.0
@export var max_fov := 80.0
@export var max_speed := 50.0

@export var look_height := 1.2

@export var look_follow_strength := -0.15

# Camera rotation lag
@export var camera_turn_speed := 3.0

# How much the camera follows velocity instead of car facing
@export var side_view_strength := 0.25

var camera_forward := Vector3.FORWARD

@export var reverse_camera_speed := 5.0

@export var drift_tilt: float = 4.0

var reverse_amount := 0.0

static var current_camera: PlayerCamera3D = null

func _ready():
	camera_forward = -car_mesh.global_basis.z
	current_camera = self


func get_speed() -> float:
	return ball.linear_velocity.length()


func get_ratio() -> float:
	
	var speed = get_speed()
	
	var speed_ratio = clamp(speed / max_speed, 0.0, 1.0)
	
	return speed_ratio


func get_forward() -> Vector3:
	
	var desired_forward := -car_mesh.global_basis.z
	
	return desired_forward


func fov_calc(delta: float) -> void:
	# =========================
	# Dynamic FOV (Fixed Frame-Rate Dependency)
	# =========================
	var speed_ratio: float = get_ratio()

	# 1. First, find out exactly what the IDEAL target FOV should be right now based on speed
	var target_fov = lerp(base_fov, max_fov, speed_ratio)
	
	# 2. Then, use delta smoothly over time to slide the camera's current FOV toward that target.
	# A speed factor of 5.0 makes the camera lens smoothly stretch out as you accelerate!
	fov = lerp(fov, target_fov, 5.0 * delta)



func camera_direction(delta: float) -> void:
	# =========================
	# Camera Direction
	# =========================

	# Which direction should the camera face?
	
		# Smooth reverse camera
	var target_reverse := 0.0
	
	var desired_forward: Vector3 = get_forward()

	reverse_amount = lerp(
		reverse_amount,
		target_reverse,
		reverse_camera_speed * delta
	)

	# Flip camera direction while reversing
	desired_forward = desired_forward.lerp(
		car_mesh.global_basis.z,
		reverse_amount
	).normalized()


func velocity(delta: float) -> void:
	var speed: float = get_speed()
	
	var desired_forward := get_forward().lerp(
		car_mesh.global_basis.z,
		reverse_amount
	).normalized()
	
	if speed > 1.0:
		var velocity_dir := -ball.linear_velocity.normalized()
		desired_forward = desired_forward.lerp(
			velocity_dir,
			side_view_strength * delta
		).normalized()

	# FIX: Force camera_forward to be perfectly 1.0 right before slerp
	camera_forward = camera_forward.normalized()
	desired_forward = desired_forward.normalized()

	camera_forward = camera_forward.slerp(
		desired_forward,
		clamp(camera_turn_speed * delta, 0.0, 1.0)
	).normalized()
	
		# --- CAMERA DRIFT SWAY TILT ---
	# Find out how fast the car is sliding sideways
	var current_right_vector = car_mesh.global_basis.x
	var slide_speed = current_right_vector.dot(ball.linear_velocity)
	
	# Turn that sliding speed into a lens tilt angle (max 4 degrees)
	var target_camera_roll = clamp(-slide_speed * 0.05, deg_to_rad(-drift_tilt), deg_to_rad(+drift_tilt))
	
	# Smoothly tilt the camera lens into the drift arc
	global_transform.basis = global_transform.basis.rotated(global_transform.basis.z, target_camera_roll * delta * 5.0)


func positioning(delta: float) -> void:
	
	var speed_ratio: float = get_ratio()
	
	# =========================
	# Camera Position
	# =========================

	var current_distance = lerp(
		distance,
		distance + 3.0,
		speed_ratio
	)

	var desired_position = car_mesh.global_position + camera_forward * current_distance + Vector3.UP * height

	global_position = global_position.lerp(
		desired_position,
		follow_speed * delta
	)


func look_ahead(delta: float) -> void:
	# ========================= #
	# Look Ahead
	# ========================= #
	
	var speed: float = get_speed()
	
	var speed_ratio: float = get_ratio()

	var look_target := car_mesh.global_position

	if speed > 0.5:

		look_target += ball.linear_velocity.normalized() * lerp(
			2.0,
			6.0,
			speed_ratio
		) * look_follow_strength

	look_target += Vector3.UP * look_height

	var target_basis := global_transform.looking_at(
		look_target,
		Vector3.UP
	).basis

	global_transform.basis = global_transform.basis.slerp(
		target_basis,
		10.0 * delta
	).orthonormalized()


func _process(delta: float):

	if ball == null or car_mesh == null:
		return
		
	fov_calc(delta)
	
	camera_direction(delta)
	
	velocity(delta)
	
	positioning(delta)
	
	look_ahead(delta)
	
	apply_screen_shake()


func apply_screen_shake() -> void:
	var strength = ScreenShake.shake_strength
	
	if strength <= 0.0:
		return
		
	# Square the strength for a snappier, more dynamic feeling asset fadeout
	var current_power = strength * strength
	
	# Calculate random offsets using the limits defined in ScreenShake
	var offset_x = randf_range(-ScreenShake.max_shake_offset.x, ScreenShake.max_shake_offset.x) * current_power
	var offset_y = randf_range(-ScreenShake.max_shake_offset.y, ScreenShake.max_shake_offset.y) * current_power
	var offset_z = randf_range(-ScreenShake.max_shake_offset.z, ScreenShake.max_shake_offset.z) * current_power
	var roll_tilt = randf_range(-ScreenShake.max_shake_roll, ScreenShake.max_shake_roll) * current_power
	
	# Displace the position using the camera's local horizontal and vertical vectors
	global_position += global_transform.basis.x * offset_x
	global_position += global_transform.basis.y * offset_y
	global_position += global_transform.basis.z * offset_z
	
	# Twist the camera slightly along its lens direction axis (Z-axis)
	global_transform.basis = global_transform.basis.rotated(global_transform.basis.z, roll_tilt)
