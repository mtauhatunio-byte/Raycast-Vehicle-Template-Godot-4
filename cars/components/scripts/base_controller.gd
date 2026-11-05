## The Basic Controller that serves as a core class to give input to the car.
class_name BaseController extends Node

## Gives motor input to the car.
var throttle : float = 0.0
## Gives steering input to the car.
var steering : float = 0.0
## Gives handbrake input to the car.
var handbrake : bool = false
