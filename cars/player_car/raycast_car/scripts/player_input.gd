class_name PlayerInput extends Node

@onready var car = get_owner() as RayCastCar

func _unhandled_input(event: InputEvent) -> void:
	car.target_throttle = Input.get_action_strength("accelerate") - Input.get_action_strength("decelerate")
	
	car.steer_input = Input.get_action_strength("steer_left") - Input.get_action_strength("steer_right")
	
	if event.is_action_pressed("handbrake"):
		car.handbreak = true
	elif event.is_action_released("handbrake"):
		car.handbreak = false
	
	if event.is_action_pressed("brake"):
		car.braking = true
	else:
		car.braking = false
