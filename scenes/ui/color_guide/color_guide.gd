extends Node2D

const Cell := preload("res://scenes/cell/cell.gd")
const cell_scene := preload("res://scenes/cell/cell.tscn")

func _on_board_manager_update_color_queue(color_queue: Array[int]) -> void:
	print(color_queue)