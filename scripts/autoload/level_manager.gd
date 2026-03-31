extends Node

var level := (preload("res://resources/levels/debug_level_collection.tres") as LevelCollection).levels[0]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for color in range(level.gradient.colors):
		print(level.gradient.get_color(color))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
