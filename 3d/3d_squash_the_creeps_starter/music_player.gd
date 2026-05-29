extends AudioStreamPlayer3D

var _original_volume
var _tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_original_volume = volume_db

func fade_out(duration: float = 3) -> void:
	_tween = create_tween()
	_tween.tween_property(self, "volume_db", -60.0, duration)
	_tween.tween_callback(stop)

func start():
	if _tween != null:
		_tween.kill()
	volume_db = _original_volume
	play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
