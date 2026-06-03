extends Node

enum Sounds {
	BALL_WALL,
	BALL_PADDLE,
	BALL_BRICK,
	LIFE_LOST,
	WIN,
	GAME_OVER,
	BONUS,
	PADDLE_BOOP,
}

@export var background_music_player: AudioStreamPlayer2D

var _players: Array[AudioStreamPlayer2D]

func _ready() -> void:
	_build_players()
	for p in _players:
		add_child(p)
	_players[Sounds.BALL_BRICK].max_polyphony = 4
	_players[Sounds.PADDLE_BOOP].max_polyphony = 3
	_players[Sounds.PADDLE_BOOP].volume_db = -5

func _build_players() -> void:
	var resources = [
		$ResourcePreloader.get_resource("tap"),
		$ResourcePreloader.get_resource("jump"),
		$ResourcePreloader.get_resource("coin"),
		$ResourcePreloader.get_resource("hurt"),
		$ResourcePreloader.get_resource("power_up"),
		$ResourcePreloader.get_resource("explosion"),
		$ResourcePreloader.get_resource("8bit-pickup2"),
		$ResourcePreloader.get_resource("8bit-jump2"),
	]
	for s in Sounds.values():
		var player = AudioStreamPlayer2D.new()
		player.stream = resources[s]
		_players.push_back(player)

func play(sound: Sounds):
	var player = _players[sound]
	if sound == Sounds.BALL_BRICK:
		player.pitch_scale = randf_range(0.8, 1.2)
	player.play()
