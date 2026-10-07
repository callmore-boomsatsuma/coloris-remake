@tool
extends Node

@export_tool_button("Generate", "Animation")var generate_action = _on_generate

const framerate := 1/60.0

@export var visual_scenes: Array[PackedScene] = []
@export var stage_node: SubViewport

const BasicCellVisuals := preload("res://scenes/cell/visuals/basic_cell_visuals.gd")

func _on_generate() -> void:
	for node in stage_node.get_children():
		stage_node.remove_child(node)
		node.queue_free()
	
	await get_tree().process_frame
	for visual_scene in visual_scenes:
		await generate_frames(visual_scene)

func generate_frames(visual_scene: PackedScene) -> void:
	var visual_scene_name := visual_scene.resource_path.get_basename().rsplit("/", true, 1)[1]
	var dir := DirAccess.open(get_script().resource_path.rsplit("/", true, 1)[0])
	dir.make_dir_recursive("output".path_join(visual_scene_name))
	
	var visual := visual_scene.instantiate() as BasicCellVisuals
	stage_node.add_child(visual)
	visual.position = stage_node.size / 2.0
	var l := visual.get_animation_base_duration()
	var frame := 0
	var tex := stage_node.get_texture()
	visual.play_visual()
	visual.set_speed(0)
	while (frame * framerate) < l:
		visual.set_time(minf(frame * framerate, l))
		await get_tree().process_frame
		tex.get_image().save_png("res://scenes/visual_generator/output/%s/%04d.png" % [visual_scene_name, frame])
		frame += 1
	visual.queue_free()
	await get_tree().process_frame
	assert(not is_instance_valid(visual))
