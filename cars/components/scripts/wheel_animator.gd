class_name WheelAnimator extends Node


@export var car : CarCore = null

@export var max_angle : float = 25.0

var velocity : float = 0.0


func _process(delta: float) -> void:
	if not car : return
	
	velocity = -car.global_basis.z.dot(car.linear_velocity)
	
	var turn : float = car.steer_input * car.turn_speed * -1
	
	for wheel : SuspensionCast in car.wheels:
		wheel.mesh.rotate_x((-velocity * delta) / wheel.wheel_radius)
		if wheel.use_as_steering:
			if turn:
				wheel.rotation.y = clampf(wheel.rotation.y + turn * delta,
				deg_to_rad(-max_angle), deg_to_rad(+max_angle))
			else:
				wheel.rotation.y = move_toward(wheel.rotation.y, 0.0, car.turn_speed * delta)
