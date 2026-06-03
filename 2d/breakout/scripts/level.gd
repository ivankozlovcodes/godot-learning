extends Node2D

signal level_brick_destroyed(score_delta: int)
signal level_cleared

@export var log_level:			= Logging.LogLevel.INFO
var logger: Logging.GameLogger

@export var grid_size: Vector2						= Vector2.ZERO
@export var brick_size: Vector2						= Vector2.ZERO
@export var level_x_side_padding_percent: float		= 0.05
@export var level_y_bottom_padding_percent: float	= 0.3
@export var padding: Vector2						= Vector2.ZERO
@export var justify_padding: bool 					= true
@export var row_colors: Array[Color]				= []
@export var randomization_chance: float				= 0.15

@export var brick_scene: PackedScene
@export var item_scene: PackedScene

var size: Vector2									= Vector2.ZERO
var viewport: Vector2								= Vector2.ZERO

var _bricks: Array[BasicBrick]						= []
var _total_grid_size: Vector2						= Vector2.ZERO

func _ready() -> void:
	logger = Logging.get_logger("level", log_level)
	_set_level_size()

	var is_viewport_big_enough = Validation.validate(_validate_brick_grid)
	if not is_viewport_big_enough.passed:
		logger.warn([is_viewport_big_enough.error])
		return

	if justify_padding:
		_justify_padding()
	_total_grid_size = brick_size * grid_size + padding * (grid_size + Vector2.ONE)
	for row in range(grid_size.y):
		for col in range(grid_size.x):
			_bricks.push_back(_create_brick_scene(row, col))
	logger.debug(["_ready", "bricks size:", _bricks.size()])

func _create_brick_scene(row: int, col: int) -> BasicBrick:
	var brick: BasicBrick = brick_scene.instantiate()
	var offset = (size - _total_grid_size) / 2
	brick.brick_size = brick_size
	brick.position = (brick_size + padding) * Vector2(col, row) + padding
	brick.position += brick_size / 2
	brick.position.x += offset.x
	brick.colors = row_colors
	brick.health = (row % row_colors.size() + 1) * 100
	if randomization_chance:
		brick.randomize(randomization_chance)
	brick.item_scene = item_scene
	logger.debug(["_create_brick_scene", "row", row, "col", col, brick.health ])
	brick.add_to_group("brick")
	add_child(brick)
	brick.destroyed.connect(_on_brick_destroyed)
	brick.spawn_item.connect(get_parent()._on_item_spawned)
	return brick

func _justify_padding() -> void:
	var _padding = padding
	var brick_occupation = brick_size * grid_size
	padding = (size - brick_occupation) / (grid_size + Vector2.ONE)
	padding.y = _padding.y

	logger.debug(["_justify_padding", "brick_occupation", brick_occupation, "grid_size", grid_size, "level_size", size])
	logger.debug(["_justify_padding", "before", _padding])
	logger.debug(["_justify_padding", "after", padding])

func _set_level_size() -> void:
	viewport = get_viewport_rect().size
	position.x = get_viewport_rect().size.x * level_x_side_padding_percent
	position.y = 25
	size = viewport - viewport * Vector2(level_x_side_padding_percent * 2, level_y_bottom_padding_percent)
	logger.debug(["_set_level_size", size, position])

func _on_brick_destroyed(points: int) -> void:
	var brick_count = get_tree().get_nodes_in_group("brick").size()
	logger.info(["_on_brick_destroyed", "bricks left", brick_count])
	level_brick_destroyed.emit(points)
	if brick_count <= 0:
		level_cleared.emit()

func _validate_brick_grid():
	logger.debug(["_validate_brick_grid", size, padding])
	var max_bricks_x_axis = int(
		(size.x - padding.x * 2) \
		/ (brick_size.x + padding.x)
	)
	var max_bricks_y_axis = int(
		(size.y - padding.y * 2) \
		/ (brick_size.y + padding.y)
	)
	var max_bricks = max_bricks_x_axis * max_bricks_y_axis
	var max_bricks_requested = grid_size.x * grid_size.y
	if max_bricks < max_bricks_requested:
		return "Bricks won't fit on viewport. Max bricks %d but requested %d" \
			% [max_bricks, max_bricks_requested]
	if max_bricks_x_axis < grid_size.x:
		return "Bricks won't fit on viewport X axis. Max bricks in a row %d but requested %d" \
			% [max_bricks_x_axis, grid_size.x]
	if max_bricks_y_axis < grid_size.y:
		return "Bricks won't fit on viewport Y axis. Max bricks %d in col but requested %d" \
			% [max_bricks_y_axis, grid_size.y]
	return ""

func _draw() -> void:
	if logger.max_level > Logging.LogLevel.DEBUG:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color.GREEN, false)

	var vp = get_viewport_rect().size
	for i in range(1, 10):
		var x = vp.x * i / 10.0 - position.x
		draw_line(Vector2(x, -position.y), Vector2(x, vp.y - position.y), Color.RED, 1)
	for i in range(1, 10):
		var y = vp.y * i / 10.0 - position.y
		draw_line(Vector2(-position.x, y), Vector2(vp.x - position.x, y), Color.RED, 1)
