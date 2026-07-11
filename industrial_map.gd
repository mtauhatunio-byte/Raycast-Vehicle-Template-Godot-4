@tool
extends Node3D

# Drag your building .tscn files directly into this array in the Inspector
@export var building_scenes: Array[PackedScene] = []

@export var area_width: float = 50.0  # Size of the spawn field
@export var area_depth: float = 50.0
@export var minimum_spacing: float = 6.0 # Crucial: Keeps buildings X meters apart!

@export var click_to_generate: bool = false : set = _on_generate_pressed

func _on_generate_pressed(_value):
	generate_clean_city()

func generate_clean_city():
	# Wipe old spawns out safely
	for child in get_children():
		child.queue_free()
		
	if building_scenes.is_empty():
		print("❌ Add your building .tscn files to the array first!")
		return
		
	var placed_positions: Array[Vector3] = []
	var attempts = 0
	var max_attempts = 300 # Safety cutoff to prevent freezing the editor

	print("🏗️ Generating perfectly spaced city zone...")

	while placed_positions.size() < 40 and attempts < max_attempts:
		attempts += 1
		
		# Pick a random spot inside your defined area dimensions
		var random_pos = Vector3(
			randf_range(-area_width / 2, area_width / 2),
			0,
			randf_range(-area_depth / 2, area_depth / 2)
		)
		
		# Check distance against every building we already placed
		var space_is_clear = true
		for pos in placed_positions:
			if random_pos.distance_to(pos) < minimum_spacing:
				space_is_clear = false
				break
				
		# If the spot passes the distance rule, spawn the building cleanly
		if space_is_clear:
			var random_building_scene = building_scenes.pick_random()
			if random_building_scene:
				var instance = random_building_scene.instantiate() as Node3D
				add_child(instance)
				instance.owner = get_tree().edited_scene_root # Makes it visible in editor
				instance.position = random_pos
				instance.rotation.y = deg_to_rad([0, 90, 180, 270].pick_random()) # Clean turns
				
				placed_positions.append(random_pos)

	print("✅ Spawning finished. Total buildings placed: ", placed_positions.size())
