@icon("uid://cg4pbj16pvb2l") class_name SkidMarksManager extends Node3D

static var instance: SkidMarksManager = null

@export var pool_size: int = 600
var pool: Array[MeshInstance3D] = []
var current_pool_index: int = 0

var last_edges_bl: Array[Vector3] = []
var last_edges_br: Array[Vector3] = []

var mat: StandardMaterial3D

func _ready() -> void:
	instance = self
	bake_mat()
	initialize_meshes()
	
func bake_mat() -> void:
	mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.05, 0.05, 0.75) # Dropped alpha slightly for a smoother blend
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.render_priority = 1
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	# --- VISUAL SMOOTHING EXTRAS ---
	mat.use_point_size = false
	# Turns on distance attenuation filters to smoothly blur out track textures from a distance
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC

	
func initialize_meshes() -> void:
	for i in pool_size:
		var segment: MeshInstance3D = MeshInstance3D.new()
		segment.material_override = mat
		add_child(segment)
		
		segment.global_position = Vector3(1000, 1000, 1000)
		pool.append(segment)
		
		
func create_skid_segment(start_pos: Vector3, end_pos: Vector3, right_vector: Vector3, is_left_tire: bool) -> void:
	# Calculate a sharp perpendicular width offset vector
	var track_width: float = 0.35
	var lateral_offset = right_vector * (track_width * 0.5)
	var road_lift = Vector3(0, 0.015, 0)
	
	# Find the center point to keep the engine rendering bounds happy
	var segment_center = (start_pos + end_pos) * 0.5
	
	# Current frame's target edges (Calculated LOCAL to the segment center)
	var current_v0 = (end_pos - lateral_offset + road_lift) - segment_center
	var current_v1 = (end_pos + lateral_offset + road_lift) - segment_center
	
	# Select our historical reference cache depending on which tyre is drawing
	var last_edges = last_edges_bl if is_left_tire else last_edges_br
	
	# Default fallback if there's no history (first frame of the drift)
	var historical_v0 = (start_pos - lateral_offset + road_lift) - segment_center
	var historical_v1 = (start_pos + lateral_offset + road_lift) - segment_center
	
	# If we have history from the previous frame, convert it into this segment's local space
	if last_edges.size() == 2:
		# We stored world-space edges, so we convert them to our current local center space
		historical_v0 = last_edges[0] - segment_center
		historical_v1 = last_edges[1] - segment_center
		
	# Update our history cache buffer with this frame's raw WORLD points for the next cycle
	var world_v0 = end_pos - lateral_offset + road_lift
	var world_v1 = end_pos + lateral_offset + road_lift
	if is_left_tire:
		last_edges_bl = [world_v0, world_v1]
	else:
		last_edges_br = [world_v0, world_v1]
		
	# Weave the triangles seamlessly (no gaps possible)
	var arr_mesh = ArrayMesh.new()
	var vertices = PackedVector3Array([
		historical_v0, historical_v1, current_v0,
		historical_v1, current_v1, current_v0
	])
	
	var normals = PackedVector3Array([Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP])
	var uvs = PackedVector2Array([Vector2(0,0), Vector2(1,0), Vector2(0,1), Vector2(1,0), Vector2(1,1), Vector2(0,1)])
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	# Recycle our object-pool node instantly
	var recycled_node = pool[current_pool_index]
	recycled_node.mesh = null
	recycled_node.mesh = arr_mesh
	
	# Teleport the container directly to the active path center to unlock camera tracking
	recycled_node.global_position = segment_center
	
	current_pool_index = (current_pool_index + 1) % pool_size
