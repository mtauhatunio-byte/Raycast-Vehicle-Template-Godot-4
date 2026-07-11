class_name PlayerCar3D extends Node3D

#region # @export variables

@export_group("Sphere Offset")
@export var sphere_offset: Vector3 = Vector3(0, 0, 0)

@export_group("Main")
@export var acceleration: float = 50
@export var steering: float = 21
@export var turn_speed: float = 5
@export var turn_stop_limit: float = 0.75
@export var body_tilt: float = 120

@export_group("Engine")
@export var max_engine_force := 50.0
@export var engine_acceleration := 45.0
@export var engine_braking := 70.0
@export var brake_strength: float = 3

var engine_force := 0.0

@export_group("Drifting (Useless)")
@export var grip := 8.0
@export var drift_grip := 2.0
@export var drift_steering_multiplier := 1.5

# --- ENGINE SOUND CONFIGURATION ---
@export_group("Sound Pitch")
@export var min_pitch: float = 0.7        # Deep engine idle hum
@export var max_pitch: float = 2.0        # High engine scream at top speed
@export var max_expected_speed: float = 50.0 # Match this to your car's top speed

var speed_input: float = 0
var rotate_input: float  = 0

@export_group("Nodes")

@export_subgroup("Miscallenous")

@export var ball: RigidBody3D
@export var car_mesh: Node3D
@export var body_mesh: MeshInstance3D
@export var ground_ray: RayCast3D

@export_subgroup("Wheels")

@export var right_wheel: MeshInstance3D
@export var left_wheel: MeshInstance3D
@export var wheel_back_right: MeshInstance3D
@export var wheel_back_left: MeshInstance3D
@export var wheels: Node3D

@export_subgroup("Smoke")

@export var left: CPUParticles3D
@export var right: CPUParticles3D

@export_subgroup("Sound Effects")

@export var engine_moving: AudioStreamPlayer3D
# OPTIONAL: If you add a tire screech AudioStreamPlayer3D inside your Sound Effects folder:
@export var tire_screech: AudioStreamPlayer3D

@export_subgroup("Labels")

@export var label: Label

@export_subgroup("Shader Rects")

@export var speed_lines_rect: ColorRect
@export var blur_rect: ColorRect

@export_subgroup("Camera")
@export var camera: PlayerCamera3D

@export_subgroup("Explosion")
@export var explosion: Node3D

#endregion

@onready var fps: Label = $"UI Layers/CanvasLayer/FPS"

@onready var noise_bus: int = AudioServer.get_bus_index("Noise")

enum MODES {FORWARD = 1, BACKWARD = -1, NULL = 0, DEAD = 2}
var mode: MODES = MODES.FORWARD

static var car: PlayerCar3D = null

@export_subgroup("Sun")
@export var SUN: DirectionalLight3D


func _ready() -> void:
	# Start engine audio immediately at idle
	engine_moving.play()
	car = self
	explosion.hide()
	wheels.show()


func _process(delta: float) -> void:
	
	fps.text = "FPS: " + str(Engine.get_frames_per_second())
	
	if mode == MODES.DEAD: return

	speed_update()
	
	ray_update()
	
	alignment(delta)
	
	car_position_update(delta)

	if not ground_ray.is_colliding(): 
		#left.emitting = false
		#right.emitting = false
		tire_screech.stop()
		return
	
	input(delta)

	drifting()

	body_tilting(delta)
	
	engine_pitch(delta)
	
	shader()


func speed_update() -> void:
	
	label.text = "SPEED: " + str(round(get_current_speed()))


func ray_update() -> void:
	ground_ray.force_raycast_update()
	ground_ray.global_position = ball.global_position
	ground_ray.target_position = Vector3.DOWN * 2.0


func alignment(delta: float) -> void:
	var n = ground_ray.get_collision_normal()
	var xform = align_with_y(car_mesh.global_transform, n)
	var next_transform = car_mesh.global_transform.interpolate_with(xform, 10 * delta)
	next_transform.basis = next_transform.basis.orthonormalized()
	car_mesh.global_transform = next_transform


func engine_pitch(delta: float) -> void:
	# Keep engine playing whenever the game is active
	
	var current_speed: float = get_current_speed()
	
	if not engine_moving.playing:
		engine_moving.play()
		
	# Calculate speed percentage (0.0 to 1.0) using the true corrected speed
	var speed_ratio: float = clamp(current_speed / max_expected_speed, 0.0, 1.0)
	
	# Dynamically shift pitch up as the vehicle accelerates
	engine_moving.pitch_scale = lerp(min_pitch, max_pitch, speed_ratio)
	
	# Dynamically blend volume (quieter at idle, louder at full throttle)
	var target: float = lerp(-10.0, 2.0, speed_ratio)
	engine_moving.volume_db = lerp(engine_moving.volume_db, target, 6.0 * delta)


func noise_scale(delta: float) -> void:
	
	var current_speed: float = get_current_speed()
	
	# Calculate speed percentage (0.0 to 1.0)
	var speed_ratio: float = clamp(current_speed / max_expected_speed, 0.0, 1.0)
	
	# Get the current volume of the bus to smooth the transition
	var current_bus_db: float = AudioServer.get_bus_volume_db(noise_bus)
	
	# Define your target volume thresholds for the wind/road noise
	# Quiet at standstill (-24.0), loud and rushing at top speed (0.0 or 2.0)
	var target_db: float = lerp(-24.0, 6.0, speed_ratio)
	
	# Smoothly interpolate the volume over time using lerp
	var new_db: float = lerp(current_bus_db, target_db, 4.0 * delta) # 4.0 keeps it smooth but responsive
	
	# Apply the new volume to the entire Noise bus
	AudioServer.set_bus_volume_db(noise_bus, new_db)


func shader() -> void:
	
	var current_speed: float = get_current_speed()
	# Calculate speed percentage (0.0 to 1.0) using the true corrected speed
	var speed_ratio: float = clamp(current_speed / max_expected_speed, 0.0, 1.0)

	# --- SEND DATA TO NOISE SHADER FROM GDSCRIPT ---
	if speed_lines_rect and speed_lines_rect.material:
		# 1. Update the base speed ratio (controls opacity and center mask size)
		speed_lines_rect.material.set_shader_parameter("car_speed_ratio", speed_ratio)
		
		# 2. Modify ANIMATION_SPEED by your car's speed
		var max_flicker_speed: float = 20.0 
		var current_flicker_speed = max_flicker_speed * speed_ratio
		speed_lines_rect.material.set_shader_parameter("animation_speed", current_flicker_speed)
		
		# 3. Modify LINE_DENSITY by your car's speed (Up to a maximum of 0.5)
		var max_density: float = 0.5
		var current_density = max_density * speed_ratio
		speed_lines_rect.material.set_shader_parameter("line_density", current_density)
		
	# --- RADIAL BLUR UPDATE LOGIC (GDSCRIPT ONLY) ---
	if blur_rect and blur_rect.material:
		# Maps the 0.0-1.0 speed ratio directly to a 0.0-0.5 blur window
		var target_blur = remap(speed_ratio, 0.0, 1.0, 0.0, 0.4)
		
		# Set a hard performance limit at 24 samples directly from code
		blur_rect.material.set_shader_parameter("samples", 24)
		
		# Push the values to the shader parameters
		blur_rect.material.set_shader_parameter("blur_strength", target_blur)


func input(delta: float) -> void:
	
	# Inside your input(delta) function, wrap your force calculations with a clamp:
	engine_force = clamp(engine_force, -max_engine_force, max_engine_force)

	
	if Input.is_action_pressed("Forward"):
		mode = MODES.FORWARD
	elif Input.is_action_pressed("Backward"):
		mode = MODES.BACKWARD
	else:
		mode = MODES.NULL
		
	
	if mode == MODES.FORWARD:
		if engine_force < -10:
			engine_force = move_toward(engine_force, 0.0, engine_acceleration * delta)
		else:
			engine_force = move_toward(engine_force, max_engine_force, engine_acceleration * delta)
	elif mode == MODES.BACKWARD:
		if engine_force > 10:
			engine_force = move_toward(engine_force, 0.0, engine_braking * delta)
		else:
			engine_force = move_toward(engine_force, -max_engine_force, engine_acceleration * delta)
	else:
		engine_force = move_toward(engine_force, 0.0, engine_braking * delta)
	
	if Input.is_action_pressed("Handbrake"):
		ball.linear_damp = brake_strength
	else:
		ball.linear_damp = 1.0


	rotate_input = 0
	rotate_input += Input.get_action_strength("Left")
	rotate_input -= Input.get_action_strength("Right")
	rotate_input *= deg_to_rad(steering)
	#if engine_force < 0:
		#rotate_input *= -1
	
	
	right_wheel.rotation.y = lerp(right_wheel.rotation.y, rotate_input, turn_speed * delta)
	left_wheel.rotation.y = lerp(left_wheel.rotation.y, rotate_input, turn_speed * delta)


func drifting() -> void:
	
	var current_speed: float = get_current_speed()
	
	var local_velocity = car_mesh.global_basis.inverse() * ball.linear_velocity
	var sideways_speed = abs(local_velocity.x)

	# --- DRIFT PARTICLES & DRIFT AUDIO MATCHING ---
	if current_speed > 30.0 and sideways_speed > 20:
		left.emitting = true
		right.emitting = true
		if not tire_screech.playing and sideways_speed > 5:
			tire_screech.play()
	else:
		left.emitting = false
		right.emitting = false
		if tire_screech.playing:
			tire_screech.stop()


func body_tilting(delta: float) -> void:
	var current_speed: float = get_current_speed()
	
	if current_speed > turn_stop_limit:
		var new_basis = car_mesh.global_transform.basis.rotated(car_mesh.global_transform.basis.y, rotate_input)
		car_mesh.global_transform.basis = car_mesh.global_transform.basis.slerp(new_basis, turn_speed * delta)
		car_mesh.global_transform = car_mesh.global_transform.orthonormalized()
		
		# --- FIXED SAFE TILT MATH ---
		# Clamp the speed factor so that driving incredibly fast doesn't cause infinite tilting
		var safe_speed_factor: float = clamp(current_speed, 0.0, max_expected_speed)
		var t = -rotate_input * safe_speed_factor / body_tilt
		
		# Hard cap the final rotation angle (e.g., deg_to_rad(25) means it can never tilt more than 25 degrees)
		var max_tilt_angle: float = deg_to_rad(25.0)
		t = clamp(t, -max_tilt_angle, max_tilt_angle)
		
		body_mesh.rotation.z = lerp(body_mesh.rotation.z, t, 10 * delta)


func car_position_update(delta: float) -> void:
	car_mesh.transform.origin.x = ball.transform.origin.x + sphere_offset.x
	car_mesh.transform.origin.z = ball.transform.origin.z + sphere_offset.z
	car_mesh.transform.origin.y = lerp(
		car_mesh.transform.origin.y,
		ball.transform.origin.y + sphere_offset.y,
		10.0 * delta
	)


func _physics_process(delta: float) -> void:
	if mode == MODES.DEAD: return

	# --- THE WALL-JAM ANTI-BOOST PROTECTION ---
	# If the sphere's actual velocity is basically 0, but your engine force is high,
	# it means you are stuck against a wall. We reset engine_force to 0 so it can't store speed.
	if ball.linear_velocity.length() < 3.0 and abs(engine_force) > 10.0:
		engine_force = 0.0
		ball.angular_velocity = Vector3.ZERO # Wipe out the spinning energy immediately

	# Apply the safe driving force forward
	ball.apply_central_force(car_mesh.global_transform.basis.z * engine_force)

	# Keep the engine audio source pinned to the car mesh
	engine_moving.global_position = car_mesh.global_position


func align_with_y(xform: Transform3D, new_y: Vector3) -> Transform3D:
	if new_y.is_zero_approx():
		return xform
	var rotation_difference := Quaternion(xform.basis.y, new_y.normalized())
	return Transform3D(Basis(rotation_difference) * xform.basis, xform.origin)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		if not event.is_echo():
			if event.keycode == KEY_R:
				explode()
			elif event.keycode == KEY_F1:
				if DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_ENABLED:
					DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
				else:
					DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
			elif event.keycode == KEY_F2:
				if SUN:
					if SUN.shadow_enabled == false:
						SUN.shadow_enabled = true
					else:
						SUN.shadow_enabled = false



func get_current_speed() -> float:
	
	var damping = max(0.001, 1.0 - get_physics_process_delta_time() * ball.linear_damp)

	return ball.linear_velocity.length() / damping


func explode() -> void:
	
	explosion.show()
	
	explosion.global_transform = body_mesh.global_transform
	
	$F1/tmpParent/suv/Explosion/Anim.play("Explode")
	
	await $F1/tmpParent/suv/Explosion/Charge.finished
	
	await get_tree().create_timer(1).timeout
	
	mode = MODES.DEAD
	
	ScreenShake.add_shake(1, 0.25)
	
	ball.apply_central_impulse(Vector3.UP * 35)
	
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	
	mat.albedo_color = Color(0, 0, 0, 1)
	
	body_mesh.set_surface_override_material(0, mat)
	
	wheel_back_left.set_surface_override_material(0, mat)
	
	wheel_back_right.set_surface_override_material(0, mat)
	
	left_wheel.set_surface_override_material(0, mat)
	
	right_wheel.set_surface_override_material(0, mat)
	
	camera.reparent(get_node("F1"))
	
	await get_tree().create_timer(3).timeout
	
	explosion.queue_free()
	
	get_tree().call_deferred("reload_current_scene")
