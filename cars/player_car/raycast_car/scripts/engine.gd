class_name EngineAudio extends AudioStreamPlayer3D


@export var car : RayCastCar = null


func _ready() -> void:
	if not car: 
		car = get_owner()
	
	play()


func _process(delta: float) -> void:
	if not car : return
	
	var speed : float = -car.global_basis.z.dot(car.linear_velocity)
	
	var speed_ratio : float = speed / car.max_speed
	
	if speed_ratio > 0.001:
		pitch_scale = lerpf(pitch_scale, speed_ratio * 1.5, 5 * delta)
		pitch_scale = clampf(pitch_scale, 0.1, car.max_speed / 10)
	else:
		pitch_scale = 0.1
		
	print("Pitch : ", pitch_scale)
