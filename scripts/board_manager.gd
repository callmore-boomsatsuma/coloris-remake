@tool

extends Node2D

@export var board_size := Vector2i(5, 5):
	set(value):
		board_size = value
		queue_redraw()
@export var cell_size := Vector2(32, 32):
	set(value):
		cell_size = value
		queue_redraw()
@export var cell_gap := Vector2(4, 4):
	set(value):
		cell_gap = value
		queue_redraw()

const Cursor := preload("res://scenes/cursor/cursor.gd")
@export var cursor_node: Cursor

const Cell := preload("res://scenes/cell/cell.gd")
const cell_scene := preload("res://scenes/cell/cell.tscn")

@export var offscreen_node_spawn_point: Node2D

var board: Array[Cell] = []

var cursor_position := Vector2i.ZERO

var input_locked := false

var color_queue: Array[int] = []

var score := 0

signal update_next_color(new_color: int)
signal add_progress(colors: Dictionary[int, int])

const SURROUNDING_CELL_OFFSETS := [
	Vector2i.UP + Vector2i.LEFT,
	Vector2i.UP,
	Vector2i.UP + Vector2i.RIGHT,
	Vector2i.LEFT,
	Vector2i.RIGHT,
	Vector2i.DOWN + Vector2i.LEFT,
	Vector2i.DOWN,
	Vector2i.DOWN + Vector2i.RIGHT,
]


func create_cell(loc: Vector2i, color_index: int) -> Cell:
	var cell := cell_scene.instantiate() as Cell
	cell.board_position = loc
	cell.global_position = get_cell_offset(loc) + global_position
	cell.level_gradient = LevelManager.level.gradient
	cell.set_color_index(color_index)
	return cell


func get_random_color_index() -> int:
	return randi_range(0, LevelManager.level.gradient.colors - 1)


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	for y in range(board_size.y):
		for x in range(board_size.x):
			var cell := create_cell(Vector2i(x, y), get_random_color_index())
			add_sibling.call_deferred(cell)
			board.push_back(cell)
	
	for i in range(2):
		color_queue.push_back(pick_random_cursor_color())
	
	update_cursor()
	update_progress_tracker()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	cursor_node.visible = not input_locked
	if input_locked:
		return
	
	for row in range(board_size.y):
		for column in range(board_size.x):
			var loc := Vector2i(column, row)
			assert(is_loc_in_bounds(loc))
			if is_cell_empty(loc) or is_cell_garbage(loc):
				continue
			var cell := cell_at(loc)
			cell.garbage_progress += delta
			if cell.garbage_progress >= LevelManager.level.garbage_time_seconds:
				cell.become_garbage()
				continue
			cell.visual_node.set_speed(1.0 + (cell.garbage_progress / LevelManager.level.garbage_time_seconds) * 3)


	var input_vec := Vector2i(
		int(Input.is_action_just_pressed(&"move_right")) - int(Input.is_action_just_pressed(&"move_left")),
		int(Input.is_action_just_pressed(&"move_down")) - int(Input.is_action_just_pressed(&"move_up"))
	)

	if input_vec != Vector2i.ZERO:
		# MOVE!
		# TODO: Play appropiate sound
		cursor_position = Vector2i(posmod(cursor_position.x + input_vec.x, board_size.x), posmod(cursor_position.y + input_vec.y, board_size.y))
		update_cursor()
		reset_selected_cell()
	
	if Input.is_action_just_pressed(&"apply_active_color"):
		var cell := get_selected_cell()
		if cell == null:
			return

		input_locked = true
		## TODO: Handle this significantly better...
		var target_color_direction := -1 if color_queue[0] == 0 else 1
		if cell.can_modify_color(target_color_direction):
			await cell.modify_color(target_color_direction)

			var chain := 0
			while true:
				var clears := find_clears()
				if clears.is_empty():
					break
				await get_tree().create_timer(0.3).timeout
				chain += 1
				var colors_cleared: Dictionary[int, int] = {}
				for cleared_cell_loc in clears:
					var cleared_cell := cell_at(cleared_cell_loc)
					if cleared_cell.color_index not in colors_cleared:
						colors_cleared[cleared_cell.color_index] = 0
					colors_cleared[cleared_cell.color_index] += 1
					cleared_cell.clear()
					for offset in SURROUNDING_CELL_OFFSETS:
						if is_loc_in_bounds(cleared_cell_loc + offset):
							print(cleared_cell_loc + offset)
							reset_garbage_progress(cleared_cell_loc + offset)
				score += len(clears) * chain
				var colors_cleared_multipled: Dictionary[int, int] = {}
				for color in colors_cleared:
					colors_cleared_multipled[color] = colors_cleared[color] * chain
				add_progress.emit(colors_cleared_multipled)
				await get_tree().create_timer(1).timeout
				# ensure that the cleared cells are gone
				while clears.any(
					func(x: Vector2i) -> bool:
						return is_instance_valid(board[board_loc_to_index(x)])
						):
						await get_tree().process_frame
				for clear in clears:
					board[board_loc_to_index(clear)] = null
				# refill!
				await apply_gravity_and_refill()

			advance_color_queue()
			update_cursor()
			update_progress_tracker()
		else:
			await cell.vibrate()
		input_locked = false


func _draw() -> void:
	if Engine.is_editor_hint():
		for y in range(board_size.y):
			for x in range(board_size.x):
				get_cell_offset(Vector2i(x, y))
				draw_rect(Rect2(get_cell_offset(Vector2(x, y)) - (cell_size / 2), cell_size), Color.WHITE, true, -1)
				draw_circle(get_cell_offset(Vector2(x, y)), 4, Color.BLUE)


## Returns if the location is in-bounds of the board.
func is_loc_in_bounds(loc: Vector2i) -> bool:
	return not ((loc.x < 0) or (loc.x >= board_size.x) or (loc.y < 0) or (loc.y >= board_size.y))


## Converts a Vector2i board location to an index.
func board_loc_to_index(loc: Vector2i) -> int:
	assert(is_loc_in_bounds(loc), "loc out of bounds! (board_size = %s, loc = %s)" % [board_size, loc])
	return loc.y * board_size.x + loc.x


func cell_at(loc: Vector2i) -> Cell:
	return board[board_loc_to_index(loc)]


## Returns if a cell is null or out of bounds.
func is_cell_empty(loc: Vector2i) -> bool:
	if not is_loc_in_bounds(loc):
		return false
	return cell_at(loc) == null


func is_cell_garbage(loc: Vector2i) -> bool:
	return cell_at(loc).is_garbage


func is_cell_immovable(loc: Vector2i) -> bool:
	return cell_at(loc).is_garbage


func can_cell_fall(loc: Vector2i) -> bool:
	if not is_loc_in_bounds(loc):
		return false
	if is_cell_empty(loc):
		return false
	if is_cell_immovable(loc):
		return false
	return is_cell_empty(loc + Vector2i.DOWN)


func cell_apply_gravity(loc: Vector2i) -> void:
	# Check how many times the cell can fall
	var fall_count := 0
	while is_cell_empty(loc + (Vector2i.DOWN * (fall_count + 1))):
		fall_count += 1
	if fall_count == 0:
		# Can't fall!
		return
	# Swap it and relocate
	var cell := cell_at(loc)
	var target_loc := loc + Vector2i.DOWN * fall_count
	board[board_loc_to_index(target_loc)] = cell
	board[board_loc_to_index(loc)] = null
	cell.relocate_to(get_cell_offset(target_loc) + global_position)


## Applies gravity to a column, and refills it if it has space at the top.
## Returns true if something happened.
func column_apply_gravity_and_refill(column: int) -> bool:
	# Skip the bottom row, gravity can never be applied to cells directly on the bottom of the grid.
	for row in range(board_size.y, -1, -1):
		var loc := Vector2i(column, row)
		if can_cell_fall(loc):
			cell_apply_gravity(loc)
			return true
	# Check if the column needs refilling.
	if is_cell_empty(Vector2i(column, 0)):
		# TODO: create cell
		var row := 0
		while is_cell_empty(Vector2i(column, row + 1)):
			row += 1
		var cell := create_cell(Vector2i(column, row), get_random_color_index())
		var old_global_pos := cell.global_position
		cell.global_position.y = offscreen_node_spawn_point.global_position.y
		cell.relocate_to(old_global_pos)
		board[board_loc_to_index(Vector2i(column, row))] = cell
		add_sibling(cell)
		return true
		
	return false


## Continuously applies gravity to the entire board until it settles.
## Awaits a small delay between cycles.
func apply_gravity_and_refill() -> void:
	while true:
		var done_something := false
		for column in range(board_size.x):
			done_something = column_apply_gravity_and_refill(column) or done_something
		if not done_something:
			break
		await get_tree().create_timer(0.2).timeout


func reset_garbage_progress(loc: Vector2i) -> void:
	if is_cell_empty(loc):
		return
	if is_cell_garbage(loc):
		return
	var cell := cell_at(loc)
	cell.garbage_progress = 0


## Calculates the offset of a cell relative to the center of this node.
func get_cell_offset(loc: Vector2) -> Vector2:
	var cell_total_size := cell_size + cell_gap
	var board_total_size := (cell_total_size * Vector2(board_size)) - cell_gap
	return (loc * cell_total_size) - (board_total_size / 2) + (cell_size / 2)


## Updates the position of the cursor.
func update_cursor() -> void:
	cursor_node.global_position = global_position + get_cell_offset(cursor_position)
	cursor_node.color = LevelManager.level.gradient.get_color(color_queue[0])

func update_progress_tracker() -> void:
	update_next_color.emit(color_queue[1])


## Returns a valid cursor color from the current level gradient.
## Will return either 0 or the amount of colors - 1 for non looping levels,
## or an even distrubution of colors between 0 and the amount of colors - 1 for looping levels.
func pick_random_cursor_color() -> int:
	# TODO: Implement looping level functionality
	var r := randi_range(0, 1)
	if r == 0:
		return 0
	else:
		return LevelManager.level.gradient.colors - 1


func advance_color_queue() -> void:
	color_queue.pop_front()
	color_queue.push_back(pick_random_cursor_color())


func reset_selected_cell() -> void:
	var cell := get_selected_cell()
	if cell == null:
		return
	cell.select_cell()


func get_selected_cell() -> Cell:
	return cell_at(cursor_position)


func find_clears() -> Array[Vector2i]:
	var clears: Dictionary[Vector2i, bool] = {}
	var clear_arrays := check_for_clears(Vector2i.DOWN) + check_for_clears(Vector2i.RIGHT)
	for clear in clear_arrays:
		clears[clear] = true
	return clears.keys()


func check_for_clears(offset: Vector2i) -> Array[Vector2i]:
	if not is_loc_in_bounds(offset):
		# impossible to contain any matches if offset is larger than the grid.
		return []
	var checked: Array[Vector2i] = []
	for row in range((board_size - offset).y):
		for column in range((board_size - offset).x):
			var loc := Vector2i(column, row)
			if loc in checked:
				continue
			if is_cell_empty(loc):
				continue
			var initial_cell := cell_at(loc)
			if initial_cell.is_garbage:
				continue
			var connected := 1
			while is_loc_in_bounds(loc + (offset * connected)) and not is_cell_empty(loc + (offset * connected)) and cell_at(loc + (offset * connected)).color_index == initial_cell.color_index:
				connected += 1
			if connected < 3:
				continue
			for i in range(connected):
				checked.push_back(loc + (offset * i))
	return checked
