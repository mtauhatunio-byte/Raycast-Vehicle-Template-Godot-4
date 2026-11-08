class_name DriftingAudio extends AudioStreamPlayer3D

@export var car : RayCastCar = null
@export var fade_speed : float = 15.0 # Controls how fast the sound cuts out

var target_volume_db : float = 0.0
var max_volume_db : float = 0.0 # Store your initial volume inspector setting

func _ready() -> void:
	if not car:
		car = get_owner()
	max_volume_db = volume_db

func _process(delta: float) -> void:
	if not car: return
	
	# Check if the car is currently executing a valid drift
	var is_drifting : bool = (car.handbreak or car.slipping) and car.grounded
	
	if is_drifting:
		target_volume_db = max_volume_db
		if not playing:
			volume_db = -80.0 # Start completely silent to avoid a sudden loud pop
			play()
	else:
		# Instead of stopping instantly, target complete silence (-80 dB)
		target_volume_db = -80.0 
		
	# Smoothly interpolate the volume to prevent audio waveform snapping
	volume_db = lerp(volume_db, target_volume_db, fade_speed * delta)
	
	# Physically stop the player only when it is fully faded out to save performance
	if not is_drifting and volume_db <= -79.0 and playing:
		stop()
