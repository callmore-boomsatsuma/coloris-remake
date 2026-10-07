extends Control


## Stores the level progress as a dictionary of color indexes to score.
var progress: Dictionary[int, int] = {}

## Maximum progress for the level. Bar cannot grow longer than this.
var max_progress: int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _draw() -> void:
	var offset := 0.0
	var target := LevelManager.level.target_cells
	for color_index in range(LevelManager.level.gradient.colors):
		if color_index not in progress:
			continue
		var color := LevelManager.level.gradient.get_color(color_index)
		var width := (progress[color_index] / float(target)) * (size.x / 2)
		print(width)
		draw_rect(Rect2((size.x / 2) + offset, 0, width, size.y), color)
		draw_rect(Rect2((size.x / 2) - width - offset, 0, width, size.y), color)
		offset += width


func add_progress(colors: Dictionary[int, int]) -> void:
	var total_progress := 0
	var target_progress := LevelManager.level.target_cells
	for v in progress.values():
		total_progress += v
	for color_index in colors:
		if color_index not in progress:
			progress[color_index] = 0
		var added_progress := mini(colors[color_index], maxi(target_progress - total_progress, 0))
		progress[color_index] += added_progress
		total_progress += added_progress
	queue_redraw()
