class_name Validation

const VALIDATOR_NULL_RETURN_MESSAGE = "validator returned null"

class ValidationResult:
	var passed: bool
	var error: String

	func _init():
		passed = false
		error = "Uninitialized"

	func success() -> ValidationResult:
		return _apply(true, "")

	func fail(message: String) -> ValidationResult:
		return _apply(false, message)

	func _apply(did_pass: bool, message: String) -> ValidationResult:
		if not did_pass and message.is_empty():
			push_error("Provide non-empty String return in validator function on fail")
		self.passed = did_pass
		self.error = message
		return self

static func validate(validator: Callable) -> ValidationResult:
	var message = validator.call()
	if message == null:
		push_error("Callable validator returned null value. Assuming fail")
		return ValidationResult.new().fail(VALIDATOR_NULL_RETURN_MESSAGE)
	if message == "":
		return ValidationResult.new().success()
	return ValidationResult.new().fail(message)
