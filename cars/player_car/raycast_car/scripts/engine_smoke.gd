extends Node3D


func _ready() -> void:
	for smoke : CPUParticles3D in get_children():
		smoke.emitting = true
		smoke.local_coords = true
