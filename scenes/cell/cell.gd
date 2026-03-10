extends Node2D

@export var board_position: Vector2i
@export var level_gradient: LevelGradient
@export var color_index: int

@export var visual_node: AbstractCellVisual

## Progress towards this cell becoming garbage. Property is controlled by the level.
var garbage_progress := 0.0
## If this cell is garbage or not. A garbage cell should not move and cannot have its color changed.
var is_garbage := false
## How many times an ajacent cell has to be cleared before this cell is cleared.
var garbage_health := 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#print(board_position)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if OS.has_feature("debug"):
		queue_redraw()
	if is_garbage:
		$GrayAnimatior.seek(0, true)
	else:
		$GrayAnimatior.seek(garbage_progress / LevelManager.level.garbage_time_seconds, true)


func _draw() -> void:
	# Debug drawing!
	if not OS.has_feature("debug"):
		return
	# draw_string(ThemeDB.fallback_font, Vector2.RIGHT * 28, "%.1f" % garbage_progress)


func set_color_index(value: int) -> void:
	color_index = value
	update_color()


func update_color() -> void:
	$Visual.modulate = get_cell_target_color()

func get_cell_target_color() -> Color:
	var new_color: Color
	if is_garbage:
		if garbage_health <= 0:
			new_color = Color.TRANSPARENT
		else:
			new_color = Color.GRAY.darkened((garbage_health) * 0.2)

	else:
		# TODO: Reevaluate if the cell should care about the level
		new_color = level_gradient.get_color(color_index)
	return new_color


func can_modify_color(offset: int) -> bool:
	# TODO: Account for looping levels.
	var result := color_index + offset
	return result >= 0 and result < level_gradient.colors


## Modifies the cells color, while also playing an animation.
func modify_color(offset: int) -> void:
	assert(color_index + offset < level_gradient.colors)
	assert(color_index + offset >= 0)

	color_index += offset
	
	visual_node.reset_visual()
	$AnimationTimer.stop()
	var tween := create_tween()
	# tween.tween_property($Visual, "modulate", level_gradient.gradient.sample(color_index / float(level_gradient.colors - 1)), 0.3)
	tween.tween_property($Visual, "modulate", get_cell_target_color(), 0.3)
	
	if offset > 0:
		$AnimationPlayer.play(&"spin")
	elif offset < 0:
		$AnimationPlayer.play_backwards(&"spin")
	await $AnimationPlayer.animation_finished
	$Visual.rotation = 0
	$AnimationTimer.start()


## Vibrates the cell when a move is invalid.
func vibrate() -> void:
	visual_node.reset_visual()
	$AnimationTimer.stop()
	var tween := create_tween()
	for i in range(16):
		tween.tween_property($Visual, "position", Vector2(randi_range(-12, 12), randi_range(-24, 24)), 0.01)
		tween.tween_interval(0.02)
	tween.tween_property($Visual, "position", Vector2.ZERO, 0.01)
	await tween.finished
	$AnimationTimer.start()


func select_cell() -> void:
	if is_garbage:
		return
	visual_node.reset_visual()
	$AnimationTimer.start()


func _on_animation_timer_timeout() -> void:
	visual_node.play_visual()


# Clears this cell, freeing it once done.
func clear() -> void:
	visual_node.reset_visual()
	$AnimationTimer.stop()
	var tween := create_tween()
	tween.tween_property($Visual, "modulate", Color.WHITE * 2, 0.5).set_ease(Tween.EASE_OUT)
	tween.tween_property($Visual, "modulate", Color.TRANSPARENT, 0.5).set_ease(Tween.EASE_IN)
	await tween.finished
	queue_free()


# Animates this cell moving to global posistion `new_loc`
func relocate_to(new_loc: Vector2) -> void:
	visual_node.reset_visual()
	$AnimationTimer.stop()
	var tween := create_tween()
	tween.tween_property(self , "global_position", new_loc, 0.2)
	await tween.finished
	$AnimationTimer.start()


## Converts this cell to garbage, turning it gray.
func become_garbage() -> void:
	visual_node.reset_visual()
	$AnimationTimer.stop()
	is_garbage = true
	garbage_health = 2
	update_color()


func damage_garbage() -> void:
	garbage_health -= 1
	$AnimationPlayer.play("garbage_damage")
	var tween := create_tween()
	tween.tween_property($Visual, "modulate", get_cell_target_color(), 0.2)
	await tween.finished
	if garbage_health <= 0:
		queue_free()
