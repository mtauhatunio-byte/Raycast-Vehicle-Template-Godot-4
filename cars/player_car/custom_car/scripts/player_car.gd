## A normal Muscle Car. 
class_name MuscleCar extends CarCore

@export var muscle : bool = true

func _ready() -> void:
	pass


func _physics_process(delta: float) -> void:
	for wheel : SuspensionCast in wheels:
		wheel.simulate_suspension()
