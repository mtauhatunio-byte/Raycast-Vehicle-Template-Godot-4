@tool extends EditorScenePostImport

const MAT: String = "uid://b5o3p2r0ju63f"

func _post_import(scene: Node) -> Object:
	var material: StandardMaterial3D = load(MAT)
	
	if not material: 
		printerr("FAILED TO FIND MATERIAL AT: " + MAT)
		return scene
	
	apply_mat(scene, material)
	
	return scene


func apply_mat(node: MeshInstance3D, material: StandardMaterial3D) -> void:
	if node is MeshInstance3D:
		node.material_override = material
		
	for child in node.get_children():
		apply_mat(child, material)
