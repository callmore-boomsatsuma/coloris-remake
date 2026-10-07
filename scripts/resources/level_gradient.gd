@tool
class_name LevelGradient
extends Resource

## Color gradient to use.
@export var gradient: Gradient:
	set(value):
		if gradient == value:
			return
		gradient = value
		emit_changed()

## How many colors are in this gradient.
@export_range(2, 16) var colors: int:
	set(value):
		if colors == value:
			return
		colors = value
		emit_changed()

## How many primary colors are in this gradient. Must be less than `colors`.
@export_range(2, 16) var primary_colors: int:
	set(value):
		if primary_colors == value:
			return
		primary_colors = value
		emit_changed()

func _init(p_gradient: Gradient = null, p_colors: int = 2, p_primary_colors: int = 2) -> void:
	gradient = p_gradient if p_gradient else Gradient.new()
	colors = p_colors
	primary_colors = p_primary_colors

	if primary_colors > 2 and (colors % primary_colors > 0):
		print("Invalid gradient definition %s, uneven number of colors for primary colors." % resource_path)

## Returns the color at index.
## index must be between 0 and number of colors - 1.
func get_color(index: int) -> Color:
	assert(index >= 0)
	assert(index < colors)

	var num_colors := colors - 1 if primary_colors == 2 else colors
	return gradient.sample(index / float(num_colors))

## Returns the primary color at index.
## index must be between 0 and number of primary colors - 1.
## if number of primary colors is greater than 2, will return colors as if they loop.
func get_primary_color(index: int) -> Color:
	assert(index >= 0)
	assert(index < primary_colors)

	if primary_colors == 2:
		return gradient.sample(index / float(primary_colors - 1))
	return gradient.sample((index / float(primary_colors))) ## Don't subtract one so that it loops.

func primary_color_to_color(primary_color: int) -> int:
	assert(primary_color >= 0)
	assert(primary_color < primary_colors)

	if primary_color == 2:
		return (colors - 1) * primary_color
	var colors_per_primary_color := get_colors_per_primary_color()
	return colors_per_primary_color * primary_color

func get_colors_per_primary_color() -> int:
	assert(colors % primary_colors == 0)
	if primary_colors == 2:
		return colors - 1
	return int(colors / float(primary_colors))
