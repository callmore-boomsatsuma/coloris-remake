@tool
class_name LevelCollection

@export var levels: Array[LevelDefinition]

func _init(p_levels: Array[LevelDefinition] = []) -> void:
    levels = p_levels
