@tool
extends AbstractCellVisual

@export var animated_sprite: AnimatedSprite2D

func play_visual() -> void:
	animated_sprite.play(&"sweep")

func reset_visual() -> void:
	animated_sprite.stop()

func set_speed(new_speed: float) -> void:
	animated_sprite.speed_scale = new_speed
