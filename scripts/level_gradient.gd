@tool
class_name LevelGradient
extends Resource

@export var gradient: Gradient:
	set(value):
		if gradient == value:
			return
		gradient = value
		emit_changed()
@export_range(2, 16) var colors: int:
	set(value):
		if colors == value:
			return
		colors = value
		emit_changed()

func _init(p_gradient: Gradient = null, p_colors: int = 0) -> void:
	gradient = p_gradient if p_gradient else Gradient.new()
	colors = p_colors

## Returns the color at index.
## index must be between 0 and number of colors - 1
func get_color(index: int) -> Color:
	assert(index >= 0)
	assert(index < colors)
	
	return gradient.sample(index / float(colors - 1))
