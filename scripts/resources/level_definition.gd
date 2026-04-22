@tool
class_name LevelDefinition
extends Resource

## Level gradient to use for this level.
@export var gradient: LevelGradient
## How long until block turn into garbage in seconds.
@export var garbage_time_seconds: float = 120.0
## Target cells cleared for the level to end.
@export var target_cells: int = 300
## Size of grid for the level.
@export var grid_size: Vector2i = Vector2i(5, 5)

func _init(
	p_gradient: LevelGradient = null,
	p_garbage_time_seconds := 120.0,
	p_target_cells:=300,
	p_grid_size := Vector2i(5, 5)):
	gradient = p_gradient
	garbage_time_seconds = p_garbage_time_seconds
	target_cells = p_target_cells
	grid_size = p_grid_size
