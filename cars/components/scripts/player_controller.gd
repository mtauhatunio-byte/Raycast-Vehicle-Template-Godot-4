## A class extending from BaseController that sets the values of BaseController using player input.
class_name PlayerController extends BaseController


func _process(delta: float) -> void:
	throttle = Input.get_action_strength("accelerate") - Input.get_action_strength("decelerate")
	steering = Input.get_action_strength("steer_right") - Input.get_action_strength("steer_left")
	handbrake = Input.is_action_pressed("handbrake")
	
	print("Throttle : ", throttle)
