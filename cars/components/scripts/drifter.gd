class_name Drifter extends Node


@export_group("Modules")
## The Car.
@export var car : CarCore = null

@export_group("Drift")
## Lower values (e.g. 8.0) make the car slide wide. Higher values grip up faster.
@export var drift_slip_responsiveness : float = 9.0
## How aggressively the nose snaps into the turn when you tap to drift.
@export var steering_boost_factor : float = 1.75
## How easily counter-steering cancels the drift (0.1 = instant grip, 0.5 = loose tail)
@export var straighten_threshold : float = 0.25


## Checker to check if the car is drifting
var drifting : bool = false
## I have no idea?!
var last_handbrake_state : bool = false

func _ready() -> void:
	assert(car != null, "DriftModule: Please assign a 'car' node link!")


func drift(current_sideways_speed : float, current_forward_speed : float, step : float) -> float:
	if not car : return current_sideways_speed
	
	var handbraking : bool = car.handbrake_input and not last_handbrake_state
	last_handbrake_state = car.handbrake_input
	
	if handbraking and absf(car.steer_input) > 0.1 and absf(current_forward_speed) > 10.0:
		drifting = true
	
	
	if drifting:
		if absf(current_forward_speed) < 4.0:
			drifting = false
		var countering : bool = (current_sideways_speed * car.steer_input) > 0.0
		if absf(car.steer_input)< straighten_threshold or (countering and absf(car.steer_input) > 0.5): 
			drifting = false
	
	if drifting:
		var target_slide : float = -car.steer_input * (car.max_speed * car.engine.drift_slide_factor)
		return lerpf(current_sideways_speed, target_slide, drift_slip_responsiveness * step)
	else:
		return lerpf(current_sideways_speed, 0.0, 24.0 * step)
