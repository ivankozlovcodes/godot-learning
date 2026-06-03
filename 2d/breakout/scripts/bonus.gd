extends CharacterBody2D
class_name Bonus

signal hit_paddle(type: Type)

enum Type { FIREBALL, MULTI_BALL, WIDE_PADDLE, FAST_BALL }

@export var bonus_type: Type				= Type.FIREBALL
@export var start_velocity: Vector2			= Vector2(0, 50)

func enable() -> void:
	velocity = start_velocity

func disable() -> void:
	velocity = Vector2.ZERO

func _ready() -> void:
	enable()

func _process(delta: float) -> void:
	var collission: KinematicCollision2D = move_and_collide(velocity * delta)
	if collission and collission.get_collider().is_in_group("paddle"):
		hit_paddle.emit(bonus_type)
		AudioManager.play(AudioManager.Sounds.BONUS)
		queue_free()
