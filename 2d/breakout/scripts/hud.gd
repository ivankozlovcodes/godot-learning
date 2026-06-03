extends CanvasLayer

signal no_lives_left

var _score 						= 0
var _lives 						= 3
var _hearts: Array[Node]		= []

func update_lives(delta: int) -> void:
	if delta > 0:
		push_error("update_lives with delta > 0 is not supported")
		return

	_lives += delta
	if _lives >= 0:
		_destroy_heart(_hearts[_lives])
	if _lives <= 0:
		no_lives_left.emit()

func update_score(delta: int) -> void:
	_score += delta
	$Score.text = "Score: %d" % _score

func display_message(message: String) -> void:
	$Message.text = message

	$Fade.show()
	$Message.show()

func _ready() -> void:
	_hearts = [$Lives/heart3, $Lives/heart2, $Lives/heart]
	_lives = _hearts.size()

func _on_main_last_ball_out_of_bounds() -> void:
	update_lives(-1)
	AudioManager.play(AudioManager.Sounds.LIFE_LOST)

func _destroy_heart(heart: TextureRect) -> void:
	var particles = heart.get_node("breakParticles")
	heart.custom_minimum_size = heart.size
	heart.texture = null
	particles.emitting = true
	particles.finished.connect(heart.queue_free)
	var tween = create_tween()
	tween.set_loops(3)
	tween.tween_property($Lives, "modulate:a", 1, 0.1)
	tween.chain().tween_property($Lives, "modulate:a", 0, 0.3)
	tween.chain().tween_property($Lives, "modulate:a", 1, 0.2)
