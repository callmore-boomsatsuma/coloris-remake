extends Control


## Stores the level progress as a dictionary of color indexes to score.
var progress: Dictionary[int, int] = {}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _draw() -> void:
	var offset := 0
	print(progress)
	for color_index in range(LevelManager.level.gradient.colors):
		if color_index not in progress:
			continue
		var color := LevelManager.level.gradient.get_color(color_index)
		draw_rect(Rect2((size.x / 2) + offset, 0, progress[color_index], size.y), color)
		draw_rect(Rect2((size.x / 2) - progress[color_index] - offset, 0, progress[color_index], size.y), color)
		offset += progress[color_index]


func add_progress(colors: Dictionary[int, int]) -> void:
	for color_index in colors:
		if color_index not in progress:
			progress[color_index] = 0
		progress[color_index] += colors[color_index]
	queue_redraw()
