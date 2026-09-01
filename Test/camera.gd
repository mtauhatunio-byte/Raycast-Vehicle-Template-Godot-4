class_name CameraFollow extends Camera3D

@export var min_distance: float = 4.0
@export var max_distance: float = 8.0
@export var height: float = 3.0
@export var sensitivity: float = 0.001

@export var target: Node3D = null
@export var pivot: Node3D = null

@export var camera_follow: bool = false
@export var camera_rotate: bool = true

@export var side_cam: Camera3D = null

var current_cam: int = 0

func _ready() -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	
	if not camera_rotate: return
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif Input.is_key_pressed(KEY_ESCAPE):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		top_level = false
		pivot.rotate_y(-event.screen_relative.x * sensitivity)
		top_level = true
		
	if Input.is_key_pressed(KEY_T) and current_cam == 0:
		current_cam = 1
	elif Input.is_key_pressed(KEY_T) and current_cam == 1:
		current_cam = 0

func _process(delta: float) -> void:
	
	if not target: return
	
	var from_target: Vector3 = global_position - target.global_position
	
	if from_target.length() < min_distance:
		from_target = from_target.normalized() * min_distance
	elif from_target.length() > max_distance:
		from_target = from_target.normalized() * max_distance
		
	from_target.y = height
	global_position = target.global_position + from_target
	
	var look_dir: Vector3 = global_position.direction_to(target.global_position).abs() - Vector3.UP
	if not look_dir.is_zero_approx():
		look_at_from_position(global_position, target.global_position, Vector3.UP)
		
	if not side_cam: return
	
	match current_cam:
		0:
			self.current = true
			side_cam.current = false
		1:
			self.current = false
			side_cam.current = true
		_:
			pass
