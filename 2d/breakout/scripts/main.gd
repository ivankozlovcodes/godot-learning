extends Node2D

signal last_ball_out_of_bounds

@export var log_level: int	= Logging.LogLevel.DEBUG
@export var state: State	= State.INITIAL

enum State { INITIAL, PAUSED, PLAYING, GAME_OVER, WIN, FINAL }

var _balls: Array[Ball]							= []
var _logger;
var _state_funcs: Dictionary[State, Callable]	= {}

func _ready() -> void:
	_logger = Logging.get_logger("main", log_level)
	_state_funcs = {
		State.PAUSED: _state_paused,
		State.PLAYING: _state_playing,
		State.FINAL: _state_final,
	}
	_reset_scene()
	_set_state(State.PAUSED)

func _reset_scene() -> void:
	var col_shape = $Paddle.get_node("CollisionShape2D")
	var paddle_collision_shape_size = Vector2(col_shape.shape.height, col_shape.shape.radius)
	var new_ball_position = $Paddle.position + Vector2(paddle_collision_shape_size.x / 4,
		-paddle_collision_shape_size.y * 2)
	$Ball.reset(new_ball_position)
	for b in _balls:
		if b != $Ball:
			b.queue_free()
	_balls = [$Ball]

@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	if OS.is_debug_build():
		_enable_cheats()
	if state in _state_funcs:
		_state_funcs[state].call()

func _state_paused() -> void:
	if Input.is_action_just_pressed("ui_accept"):
		_set_state(State.PLAYING)

func _state_playing() -> void:
	if Input.is_action_just_pressed("ui_accept"):
		_set_state(State.PAUSED)

func _state_final() -> void:
	if Input.is_action_just_pressed("restart"):
		_reset_scene()
		get_tree().reload_current_scene()

func _set_state(new_state: State) -> void:
	var state_change = "%s -> %s" % [State.keys()[state], State.keys()[new_state]]
	match [state, new_state]:
		[State.PAUSED, State.PLAYING]: _on_start_resume_game()
		[State.INITIAL, State.PAUSED]: _on_pause_game()
		[State.PLAYING, State.PAUSED]: _on_pause_game()
		[_, State.WIN]:
			_finish_level("You've won!")
			AudioManager.play(AudioManager.Sounds.WIN)
			new_state = State.FINAL
		[_, State.GAME_OVER]:
			_finish_level("Game Over!")
			AudioManager.play(AudioManager.Sounds.GAME_OVER)
			new_state = State.FINAL
		_: _logger.debug("Transition %s is a noop" % state_change)
	_logger.info(state_change)
	state = new_state

func _on_start_resume_game() -> void:
	for b in _balls:
		b.enable()
	for n in get_tree().get_nodes_in_group("bonus"):
		n.enable()
	$Paddle.enable()

func _on_pause_game() -> void:
	for b in _balls:
		b.disable()
	for n in get_tree().get_nodes_in_group("bonus"):
		n.disable()
	$Paddle.disable()

func _finish_level(message) -> void:
	$HUD.display_message(message)
	$Paddle.disable()
	$WallBottom/CollisionShape2D.disabled = false

func _on_hud_no_lives_left() -> void:
	_set_state(State.GAME_OVER)

func _on_ball_out_of_bounds(ball: Ball) -> void:
	_balls.erase(ball)
	if ball != $Ball:
		ball.queue_free()
	if _balls.is_empty():
		_reset_scene()
		_set_state(State.PAUSED)
		last_ball_out_of_bounds.emit()

func _on_level_level_cleared() -> void:
	_set_state(State.WIN)

func _spawn_new_ball() -> void:
	var ball = _balls[randi_range(0, _balls.size() - 1)]
	var new_ball = ball.duplicate() as Ball
	new_ball.out_of_bounds.connect(_on_ball_out_of_bounds.bind(new_ball))
	new_ball.hit.connect($Paddle._on_ball_hit.bind("ball"))
	new_ball._last_known_velocity = ball._last_known_velocity + \
		Vector2(randi_range(-10, 10), randi_range(-10, 10))
	new_ball.velocity += Vector2(randi_range(-10, 10), randi_range(-10, 10))
	new_ball._last_known_velocity = new_ball._last_known_velocity.rotated(deg_to_rad(20))
	new_ball.velocity = new_ball.velocity.rotated(deg_to_rad(20))
	new_ball.reset_bonuses()
	_balls.push_back(new_ball)
	add_child(new_ball)

func _fireballs():
	for b in _balls:
		@warning_ignore("integer_division")
		b.fireball(5 / _balls.size() + 1)

func _fast_ball():
	for b in _balls:
		b.fastball()

func _on_bonus_hit_paddle(type: Bonus.Type) -> void:
	match type:
		Bonus.Type.FIREBALL: _fireballs()
		Bonus.Type.MULTI_BALL: _spawn_new_ball()
		Bonus.Type.WIDE_PADDLE: $Paddle.wide_paddle()
		Bonus.Type.FAST_BALL: _fast_ball()

func _on_item_spawned(item: Node) -> void:
	item.connect('hit_paddle', _on_bonus_hit_paddle)

#region dev cheat
var cheat_timer: SceneTreeTimer
var cheat_buffer: String
var CHEATS = {
	"fire": func(): _on_bonus_hit_paddle(Bonus.Type.FIREBALL),
	"mmm": func(): _on_bonus_hit_paddle(Bonus.Type.MULTI_BALL),
	"long": func(): _on_bonus_hit_paddle(Bonus.Type.WIDE_PADDLE),
	"fast": func(): _on_bonus_hit_paddle(Bonus.Type.FAST_BALL),
}

func _clear_cheat_buffer() -> void:
	cheat_buffer = ""

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if is_instance_valid(cheat_timer):
			cheat_timer.timeout.disconnect(_clear_cheat_buffer)
		cheat_timer = get_tree().create_timer(1)
		cheat_timer.timeout.connect(_clear_cheat_buffer)
		if event.unicode > 31:
			cheat_buffer += char(event.unicode)
	for cheat_key in CHEATS:
		if cheat_buffer.ends_with(cheat_key):
			CHEATS[cheat_key].call()

func _enable_cheats() -> void:
	if Input.is_action_just_pressed("ui_text_backspace"):
		_clear_blocks()
	if Input.is_action_just_pressed("die"):
		$HUD.update_lives(-1000)

func _clear_blocks() -> void:
	for child in $Level.get_children():
		child.hit()

#endregion
