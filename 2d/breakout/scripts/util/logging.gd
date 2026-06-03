class_name Logging

enum LogLevel { VERBOSE, DEBUG, INFO, WARN, ERROR }

class GameLogger extends RefCounted:
	var tag: String
	var max_level: int

	func setup(t: String, lvl: LogLevel) -> GameLogger:
		tag = t
		max_level = lvl
		return self

	func verbose(argv: Variant) -> void: _log(LogLevel.VERBOSE, argv)
	func debug(argv: Variant) -> void: _log(LogLevel.DEBUG, argv)
	func info(argv: Variant) -> void: _log(LogLevel.INFO, argv)
	func warn(argv: Variant) -> void: _log(LogLevel.WARN, argv)
	func error(argv: Variant) -> void: _log(LogLevel.ERROR, argv)

	func _log(level: int, argv: Variant) -> void:
		if level < max_level:
			return
		var prefix = "[%s][%s]" % [tag, LogLevel.keys()[level]]
		var message = argv
		if argv is Array:
			message = " ".join(argv.map(func(a): return str(a)))
		print("%s %s" % [prefix, message])


static func get_logger(tag: String, max_level: LogLevel) -> GameLogger:
	return GameLogger.new().setup(tag, max_level)
