@tool
extends AbstractCellVisual

@export var animation_player: AnimationPlayer

func play_visual() -> void:
	animation_player.play(&"sweep")

func reset_visual() -> void:
	animation_player.play(&"RESET")

func set_speed(new_speed: float) -> void:
	animation_player.speed_scale = new_speed

func get_animation_base_duration() -> float:
	return animation_player.get_animation(&"sweep").length

func set_time(new_time: float) -> void:
	animation_player.seek(new_time, true)
