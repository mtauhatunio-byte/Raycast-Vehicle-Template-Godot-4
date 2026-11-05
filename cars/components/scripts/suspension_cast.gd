## Wheels that use raycasts to simulate suspension and springs.
class_name SuspensionCast extends RayCast3D

@export_group("Nodes")
## Must assign a car node to work.
@export var car : CarCore = null
## The visual mesh of the wheel.
@export var mesh : MeshInstance3D = null
## Assign a shapecast if you have one to get more accurate calculations.
@export var shapecast : ShapeCast3D = null
## DRIFT MARKS BABY!!!!!!
@export var drift_marks : CPUParticles3D = null

@export_group("Spring")
## Should the wheel use suspenions.
@export var suspension : bool = true
## How strong the wheel spring is.
@export var spring_strength : float = 12000.0
## How fast the spring force goes towards 0.0.
@export var spring_damping : float = 800.0
## How high up the wheel is off the ground
@export var rest_distance : float = 0.4
## The radius of the wheel mesh. (Pretty self-explanatory).
@export var wheel_radius : float = 0.4
## How much does the spring extend past the normal value. Good for making the car more stable.
@export var over_extend : float = 0.2

@export_group("Motor")
## Should the wheel be used as steering.
@export var use_as_steering : bool = false
## Should the wheel be used as traction.
@export var use_as_traction : bool = false

@export_group("Physics")
## Should the wheel's calculations happen before anything else or not.
@export var prioritized : bool = true

## A boolean to check if the wheel is on the ground.
var grounded : bool = false
## A float that tells how long the ray is.
var ray_length : float = 0.0


func _ready() -> void:
	for child in get_children():
		if child is ShapeCast3D and not shapecast:
			shapecast = child as ShapeCast3D
		if child is MeshInstance3D and not mesh:
			mesh = child as MeshInstance3D
		if child is CPUParticles3D and not drift_marks:
			drift_marks = child as CPUParticles3D
		
	if drift_marks: drift_marks.show()
	
	ray_length = -(rest_distance + wheel_radius + over_extend)
	
	if shapecast:
		enabled = false
		shapecast.enabled = true
		shapecast.target_position.y = ray_length
		shapecast.force_shapecast_update()
	else:
		enabled = true
		target_position.y = ray_length
		force_raycast_update()
	
	process_physics_priority = -1 if prioritized else 0
	
	
	assert(car != null, "SuspensionCast : Please assign a 'car' node!!!")


## Simulates the suspension and spring of the wheels using raycasts.
func simulate_suspension() -> void:
	if not car or not suspension : return
	
	ray_length = -(rest_distance + wheel_radius + over_extend)
	
	if shapecast:
		shapecast.target_position.y = ray_length
		shapecast.force_shapecast_update()
	else:
		target_position.y = ray_length
		force_raycast_update()
	
	var sensor : Node3D = null
	
	if shapecast:
		sensor = shapecast as ShapeCast3D
	else:
		sensor = self as RayCast3D
	
	grounded = sensor.is_colliding()
	car.grounded = sensor.is_colliding()
	
	if grounded:
		var contact : Vector3 = Vector3.ZERO
		var normal : Vector3 = Vector3.ZERO
		var up : Vector3 = car.global_basis.y
		
		contact = sensor.get_collision_point(0) if shapecast else sensor.get_collision_point()
		normal = sensor.get_collision_normal(0) if shapecast else sensor.get_collision_normal()
		
		var pos : Vector3 = shapecast.global_position if shapecast else global_position
		
		var spring_length : float = pos.distance_to(contact) - wheel_radius
		var offset : float = rest_distance - spring_length
		
		if mesh:
			mesh.position.y = -spring_length
		
		var spring_force : float = offset * spring_strength
		
		var world_velocity : Vector3 = car.get_point_velocity(contact)
		var local_velocity : float = up.dot(world_velocity)
		var spring_damp_force : float = spring_damping * local_velocity
		
		var force_vector : Vector3 = (spring_force - spring_damp_force) * normal
		
		var target_mesh_pos : Vector3 = mesh.global_position if mesh else global_position
		var force_pos : Vector3 = target_mesh_pos - car.global_position
		
		if drift_marks:
			if car.handbrake_input:
				drift_marks.emitting = true
			else:
				drift_marks.emitting = false
		
		DebugDraw3D.draw_arrow_ray(contact, force_vector/car.mass, 0.5, Color.BLUE, 0.05)
		
		#DebugDraw3D.draw_sphere(get_collision_point(), 0.5, Color.ORANGE)
		
		car.apply_force(force_vector, force_pos)
	
	else:
		if mesh:
			mesh.position.y = move_toward(
				mesh.position.y, 
				-rest_distance, 
				4.0 * get_physics_process_delta_time()
				)
