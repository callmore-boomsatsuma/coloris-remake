@tool

extends Node2D

@onready var trail := $Trail as Line2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	trail.top_level = true
	trail.global_transform = Transform2D.IDENTITY
	trail.clear_points()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	trail.add_point(global_position)
	if (trail.points).size() > 15:
		trail.remove_point(0)
