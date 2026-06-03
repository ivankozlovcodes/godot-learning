extends CharacterBody2D
class_name Ball

signal hit(what: String, collision_normal: Vector2)
signal out_of_bounds(ball: Ball)

var logger = Logging.get_logger("ball", Logging.LogLevel.INFO)

#region english slide
@export var radius							= 30
@export var enable_english					= true
@export var english_decay_factor			= 0.6
@export var english_strength				= 0.7
@export var color							= Color.WHITE_SMOKE

var _english = 0
#endregion

@export var speed_decay: float		= 0.9
@export var base_speed: float		= 250.0
@export var target_speed: float		= base_speed
@export var max_speed: float		= 500.0
@export var start_velocity			= Vector2(0, 200)

var polygon_points_count = 60

var _last_known_velocity: Vector2		= Vector2.ZERO
var _fireball: bool						= false
var _fireball_tween: Tween				= null
var _fireball_timer: SceneTreeTimer		= null

func reset_bonuses() -> void:
	_fireball_off()
	target_speed = base_speed

func enable() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	velocity = _last_known_velocity

func disable() -> void:
	_last_known_velocity = velocity
	process_mode = Node.PROCESS_MODE_DISABLED

func reset(new_position: Vector2) -> void:
	position = new_position
	velocity = start_velocity
	reset_bonuses()

func fireball(duration_s: int) -> void:
	_fireball_on(duration_s)

func fastball() -> void:
	target_speed = max_speed
	var tween = create_tween()
	tween.set_loops(15)
	tween.tween_property($Polygon2D, "color", Color.RED, 0.1)
	tween.chain().tween_property($Polygon2D, "color", Color.BLUE, 0.1)
	tween.finished.connect(func(): $Polygon2D.color = color)

func _fireball_on(duration_s: int) -> void:
	_fireball = true

	$Polygon2D.color = Color.CRIMSON
	$FireTrail.emitting = true

	if _fireball_timer:
		_fireball_timer.timeout.disconnect(_fireball_off)
	_fireball_timer = get_tree().create_timer(duration_s)
	_fireball_timer.timeout.connect(_fireball_off)

	if _fireball_tween:
		_fireball_tween.kill()

	_fireball_tween = create_tween()
	_fireball_tween.set_loops(10)
	_fireball_tween.tween_property($Polygon2D, 'scale', Vector2(2, 2), 0.5)
	_fireball_tween.chain().tween_property($Polygon2D, 'scale', Vector2(0.5, 0.5), 0.5)

func _fireball_off() -> void:
	_fireball = false
	if _fireball_tween:
		_fireball_tween.kill()
	$Polygon2D.scale = Vector2.ONE
	$Polygon2D.color = color
	$FireTrail.emitting = false

func _ready() -> void:
	$CollisionShape2D.shape.radius = radius

	var polygon: PackedVector2Array = \
		range(0, polygon_points_count) \
		.map(func (i): return i * 2 * PI / polygon_points_count) \
		.map(func (a): return Vector2(cos(a) * radius, sin(a) * radius))

	velocity = start_velocity
	velocity.x *= randf_range(0.8, 1.2)

	$Polygon2D.polygon = polygon
	$Polygon2D.color = color

func _physics_process(delta: float) -> void:
	logger.verbose(velocity.length())
	var collision = move_and_collide(velocity * delta)

	if collision:
		var collider = collision.get_collider()
		var normal = collision.get_normal()
		logger.verbose(["collision", normal])
		var should_bounce = false
		if collider.is_in_group("paddle"):
			if normal.y < 0: # top hit
				_collide_paddle(collision)
			else: # side or bottom hit
				should_bounce = true
		elif collider.is_in_group("brick"):
			logger.debug(["ball hit brick"])
			should_bounce = !_fireball
			if fireball and randf() < 0.7:
				AudioManager.play(AudioManager.Sounds.BALL_BRICK)
			var should_spawn_bonus = !_fireball
			(collider as BasicBrick).hit(should_spawn_bonus)
		elif collider.is_in_group("wall"):
			should_bounce = true
			AudioManager.play(AudioManager.Sounds.BALL_WALL)
		if should_bounce:
			velocity = velocity.bounce(collision.get_normal())
		logger.verbose(["_physics_process end", "velocity", velocity,
			"english", _english, "speed", velocity.length()])

		target_speed = max(base_speed, target_speed * pow(speed_decay, delta))
		velocity = velocity.normalized() * target_speed
		if abs(velocity.y) < 50:
			velocity.y = sign(velocity.y) * 50

	if _fireball:
		var mat := $FireTrail.process_material as ParticleProcessMaterial
		mat.gravity = Vector3(-velocity.x, -velocity.y, 0)

func _collide_paddle(collision: KinematicCollision2D) -> void:
	var speed = velocity.length()
	var paddle = collision.get_collider()
	hit.emit("paddle", collision.get_normal())
	AudioManager.play(AudioManager.Sounds.BALL_PADDLE)
	@warning_ignore("integer_division")
	position += collision.get_normal() * (radius / 2)
	#region angle off paddle
	var offset = position.x - paddle.position.x
	var normalized_offset = clamp(offset / (paddle.get_node("Panel").size.x / 2), -1.0, 1.0)
	var angle = normalized_offset * deg_to_rad(30)
	velocity = Vector2(sin(angle), -cos(angle)) * speed
	#endregion
	if enable_english:
		velocity.x += paddle.velocity.x * english_strength
		velocity.y = velocity.normalized().y * speed

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	if not position.y < get_viewport_rect().size.y:
		push_warning("Ball out of bounds but not below the viewport")
	logger.info(["out_of_bounds.emit()"])
	out_of_bounds.emit(self)
