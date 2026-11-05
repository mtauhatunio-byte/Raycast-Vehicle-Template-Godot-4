#region Class Documentation
## The core class that every car extends from.
##
## In simple words, it's a class, that contains the basic stuff needed to make a car.
## It has all the basic features like speed, steering, and inputs.
## It does depend on other stuff to run correctly like a BaseController and SuspensionCasts. 
#endregion
class_name CarCore extends RigidBody3D


#region Export Variables
@export_group("Engine")
## The car's top speed. The car's speed can't go past this value.
@export var max_speed : float = 20.0
## The speed at which the car moves toward the max speed.
@export var acceleration : float = 15.0
## How fast the car turns.
@export var turn_speed : float = 4.8
## The curve that controls the acceleration power based on speed.
@export var acceleration_curve : Curve = null


@export_group("Moudules")
## The controller which handles the inputs of the car.
@export var controller : BaseController = null
## The engine that controls the car's acceleration, steering etc.
@export var engine : CarEngine = null
## The Drifter
@export var drifter : Drifter = null
## An Array to tell Godot all the Wheels.
@export var wheels : Array[SuspensionCast] = []
#endregion


#region Member Variables

## Input that is acquired from the BaseController that goes between -1 and 1 to get the direction of the car to move it forwards and bacwards.
var motor_input : float = 0.0
## Input that is acquired from the BaseController that goes between -1 and 1 to get the direction of the car to move it left and right.
var steer_input : float = 0.0
## Input that is acquired from the BaseController that goes true and false based on if the car is handbreaking.
var handbrake_input : bool = false
## A simple boolean checking if the car is currently on the ground.
var grounded : bool = false
#endregion


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if controller:
		motor_input = controller.throttle
		steer_input = controller.steering
		handbrake_input = controller.handbrake


func _physics_process(delta: float) -> void:
	var ground_check : bool = true
	for wheel : SuspensionCast in wheels:
		wheel.simulate_suspension()
		if wheel.grounded:
			ground_check = true
	
	grounded = ground_check


## Gets the exact velocity of a point. It works by passing in a Vector3, the point and returns a Vector3 because velocity is a Vector3
func get_point_velocity(point : Vector3) -> Vector3:
	return linear_velocity + angular_velocity.cross(point - to_global(center_of_mass))


func _integrate_forces(state : PhysicsDirectBodyState3D) -> void:
	if engine and grounded:
		engine.process_physics_drive(state)
