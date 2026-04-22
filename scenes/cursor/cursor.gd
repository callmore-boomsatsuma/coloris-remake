@tool

extends Node2D

@export var color: Color:
	get:
		return modulate
	set(value):
		modulate = value

func _on_board_manager_move_cursor(new_global_cursor_pos: Vector2) -> void:
	position = new_global_cursor_pos

func _on_board_manager_update_color_queue(color_queue: Array[int]) -> void:
	color = LevelManager.level.gradient.get_primary_color(color_queue[0])


func _on_board_manager_input_lock_changed(new_input_lock_state: bool) -> void:
	visible = not new_input_lock_state
