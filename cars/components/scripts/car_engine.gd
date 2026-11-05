## Serves as the Engine of the car, handling all of its acceleration, steering and physics.
class_name CarEngine extends Node

@export_group("Modules")
## The car core platform shell link.
@export var car : CarCore = null

@export_group("Off-Road Tuning Spec")
## High Speed Steering Governor: Turning power multiplier at maximum speed (0.4 = 60% less turn at top speed).
@export var high_speed_turn_cap : float = 0.45


func _ready() -> void:
	assert(car != null, "CarEngine: Please assign a 'car' node link inside the Inspector panel!")
	car.custom_integrator = false


func process_physics_drive(state : PhysicsDirectBodyState3D) -> void:
	if not car: return
	
	# 1. AIRBORNE PASSIVE PHYSICS
	# If you fly off an off-road ridge or ramp, turn off the engine and steering entirely.
	# Let Godot's true physics server gravity handle the flight arc and weight naturally.
	if not car.grounded:
		car.sleeping = false
		return
	
	# 2. ISOLATE MOVEMENT DIRECTIONS (Rotation-Proof Vector Lines)
	var forward : Vector3 = -car.global_transform.basis.z.normalized()
	var right : Vector3 = car.global_transform.basis.x.normalized()
	
	# 3. FORWARD HEAVY TORQUE ACCELERATION
	var current_forward_speed : float = state.linear_velocity.dot(forward)
	var speed_ratio : float = clampf(absf(current_forward_speed) / car.max_speed, 0.0, 1.0)
	
	# Sample your visual graph curve resource for V8 engine power delivery bands
	var ac : float = 1.0
	if car.acceleration_curve:
		ac = car.acceleration_curve.sample_baked(speed_ratio)
	
	if absf(car.motor_input) > 0:
		current_forward_speed = move_toward(
			current_forward_speed,
			car.max_speed * car.motor_input,
			car.acceleration * ac * state.step
		)
	else:
		# Heavy engine compression braking drag when letting go of throttle in the dirt
		current_forward_speed = move_toward(current_forward_speed, 0.0, 18.0 * state.step)
	
	# 4. 🌟 THE UNBREAKABLE OFF-ROAD GRIP LAYER (Soft-Rails Traction)
	# Instead of keeping the side speed locked to an absolute zero stone-brick wall, 
	# we use a very fast lerp to let the tires slightly 'give' and slip under heavy mud loads, 
	# but instantly snap back onto rails so your weapon crosshairs stay completely stable.
	var sideways_speed : float = state.linear_velocity.dot(right)
	sideways_speed = lerp(sideways_speed, 0.0, 32.0 * state.step)
	
	# 5. SUSPENSION MOUNT ASSEMBLER
	# Isolate and preserve the vertical upward forces calculated by the SuspensionCast wheel scripts
	var global_up : Vector3 = state.linear_velocity.project(car.global_transform.basis.y)
	
	# Commit linear vectors safely back to the server natively
	state.linear_velocity = (forward * current_forward_speed) + (right * sideways_speed) + global_up
	
	# 6. 🌟 IMPLEMENTING YOUR SPEED-TURN RATIO GOVERNOR
	if absf(current_forward_speed) > 1.5:
		# Smoothly calculate how much we should limit our turning power as our speed increases
		var dynamic_turn_multiplier: float = lerpf(1.0, high_speed_turn_cap, speed_ratio)
		var active_turn_speed: float = car.turn_speed * dynamic_turn_multiplier
		
		# Set an immediate, sharp turning rotation velocity around the car's vertical axis
		var target_yaw : float = -car.steer_input * active_turn_speed
		state.angular_velocity.y = lerp(state.angular_velocity.y, target_yaw, 15.0 * state.step)
	else:
		state.angular_velocity.y = lerp(state.angular_velocity.y, 0.0, 10.0 * state.step)
