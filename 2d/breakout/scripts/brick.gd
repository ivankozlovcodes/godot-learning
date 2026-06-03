@tool

class_name BasicBrick

extends StaticBody2D

signal destroyed(points: int)
signal spawn_item(item: Node)

@export var item_scene: PackedScene
@export var item_chance: float		= 0.1

@export var brick_size: Vector2		= Vector2.ZERO
@export var points: int				= 1
@export var health: float			= 100.0
var colors: Array[Color]			= []

func _ready() -> void:
	$ColorRect.size = brick_size
	$ColorRect.position = -brick_size / 2
	$CollisionShape2D.shape.size = brick_size * 1.1
	$HP.text = str(health)
	update_color()
	queue_redraw()
	if Engine.is_editor_hint():
		return

func randomize(randomization_chance: float) -> void:
	var max_health = colors.size() * 100
	var rand_sign = sign(randf_range(-1, 1))
	if randf() < randomization_chance:
		if health == max_health:
			rand_sign = -1
		health += rand_sign * 100

func update_color() -> void:
	var color_idx: int  = (health / 100) - 1
	if color_idx < colors.size():
		$ColorRect.color = colors[color_idx]

func hit(should_spawn_item_if_destroyed: bool = true) -> void:
	health -= 100
	if health <= 0:
		destroy(should_spawn_item_if_destroyed)
	else:
		item_chance += randf_range(0.01, 0.05)
	@warning_ignore("narrowing_conversion")
	$HP.text = str(health)
	update_color()

func destroy(should_spawn_item_if_destroyed: bool = true) -> void:
	remove_from_group("brick")
	destroyed.emit(points)
	$CollisionShape2D.set_deferred("disabled", true)
	if (should_spawn_item_if_destroyed):
		_spawn_item()
	_die_animation()

func _spawn_item() -> void:
	if item_scene and randf() < item_chance:
		var item = item_scene.instantiate()
		item.position = position
		item.bonus_type = randi_range(0, Bonus.Type.size() - 1) as Bonus.Type
		get_parent().add_child(item)
		spawn_item.emit(item)

func _die_animation() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * 1.5, 0.1)
	tween.parallel().tween_property($ColorRect, "color", Color.RED, 0.1)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
	tween.tween_callback(queue_free)
