extends CharacterBody2D

@export var log_level: int = Logging.LogLevel.INFO
var log: Logging.GameLogger

@export var speed				= 300
@export var friction_strength	= 4
@export var paddle_size: Vector2 = Vector2(100, 15)

var wall_padding					= 5
var _friction						= 0
var _size_modifier: float			= 1.0
var _size_modifier_decay: float		= 0.9

#region spring
const ENABLE_SPRING = false
var spring_velocity: Vector2 = Vector2(0, 0)				# current speed of visual dip (px/s)
var stiffness: float = 3									# how hard spring pulls back to rest (higher = snappier)
var damping: float = 0.000001								# energy loss rate per second (lower = faster decay with pow())
var dip_strength: float = 120								# impulse added to spring_velocity.yon ball hit
var offset_y: float = 0										# current visual displacement from rest position (px)
var color_rect_start_position: Vector2 = Vector2(0, 0)		# starting position of visible paddle
#endregion

#region bounce
@export var bounce_strength: int = 6

const ENABLE_BOUNCE = true
var _bounce_tween: Tween = null
#endregion

var _last_known_velocity: Vector2;

func enable() -> void:
	velocity = _last_known_velocity
	process_mode = Node.PROCESS_MODE_ALWAYS

func disable() -> void:
	_last_known_velocity = velocity
	process_mode = Node.PROCESS_MODE_DISABLED

func wide_paddle() -> void:
	_size_modifier = 2

func _ready() -> void:
	log = Logging.get_logger("paddle", log_level)
	_friction = speed * friction_strength
	paddle_size = $Panel.size
	color_rect_start_position = $Panel.position

func _physics_process(delta: float) -> void:
	if _size_modifier != 1:
		_size_modifier = max(1.0, _size_modifier * pow(_size_modifier_decay, delta))
		$Panel.size.x = paddle_size.x * _size_modifier
		$Panel.position.x = -$Panel.size.x / 2
		$CollisionShape2D.shape = $CollisionShape2D.shape.duplicate()
		$CollisionShape2D.shape.height = $Panel.size.x * 1.1

	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, delta * _friction)
	$Panel.position.y = color_rect_start_position.y + offset_y
	log.debug([offset_y])

	if ENABLE_SPRING:
		_spring(delta)
	var collision: KinematicCollision2D = move_and_collide(velocity * delta)
	if collision and collision.get_collider().is_in_group("wall"):
		var tween = create_tween()
		tween.tween_property(self, "position:x", position.x - sign(velocity.x) * 20, 0.2)
		AudioManager.play(AudioManager.Sounds.PADDLE_BOOP)
		velocity.x = -velocity.x

func _spring(delta: float) -> void:
	if is_zero_approx(offset_y) and is_zero_approx(spring_velocity.y):
		offset_y = 0
		spring_velocity.y = 0
		return
	if offset_y != 0:
		log.info([offset_y])
	spring_velocity.y += -stiffness * offset_y
	spring_velocity.y *= pow(damping, delta)
	offset_y += spring_velocity.y * delta
	$Panel.position.y = color_rect_start_position.y + offset_y

func _bounce_once() -> void:
	if _bounce_tween:
		_bounce_tween.kill()
	_bounce_tween = create_tween()
	var bounce_y = $Panel.position.y + bounce_strength
	_bounce_tween.tween_property($Panel, "position:y", bounce_y, 0.05)
	_bounce_tween.chain().tween_property($Panel, "position:y", color_rect_start_position.y, 0.08)

func _on_ball_hit(what: String, collission_normal: Vector2) -> void:
	var top_hit = collission_normal.y < -0.7 # cos(45deg) ~ 0.707
	if what == "paddle":
		log.info(["ball hit paddle"])
		if top_hit:
			if ENABLE_SPRING:
				spring_velocity.y += dip_strength
			if ENABLE_BOUNCE:
				_bounce_once()
