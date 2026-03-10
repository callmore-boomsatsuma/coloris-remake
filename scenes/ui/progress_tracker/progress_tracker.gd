@tool
extends Control

var stylebox := preload("res://scenes/ui/progress_tracker/default_progress_border.tres").duplicate() as StyleBoxFlat

const ProgressTrackerBar := preload("res://scenes/ui/progress_tracker/progress_tracker_bar.gd")
@export var progress_tracker_bar_node: ProgressTrackerBar

@export var border_color: Color = Color.WHITE:
	get:
		return stylebox.border_color
	set(value):
		stylebox.border_color = value


func _ready() -> void:
	($PanelContainer as PanelContainer).add_theme_stylebox_override(&"panel", stylebox)


func add_progress(colors: Dictionary[int, int]) -> void:
	progress_tracker_bar_node.add_progress(colors)


func _on_board_manager_add_progress(colors: Dictionary[int, int]) -> void:
	add_progress(colors)


func _on_board_manager_update_next_color(new_color: int) -> void:
	border_color = LevelManager.level.gradient.get_color(new_color)
