@tool
class_name LevelDefinition
extends Resource

## Level gradient to use for this level
@export var gradient: LevelGradient
## How long until block turn into garbage in seconds.
@export var garbage_time_seconds: float = 120.0

func _init(p_gradient: LevelGradient = null, p_garbage_time_seconds: float = 120.0):
	gradient = p_gradient
	garbage_time_seconds = p_garbage_time_seconds
