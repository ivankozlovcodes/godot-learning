extends CharacterBody3D

signal hit

const SPEED = 14
const JUMP_VELOCITY = 4.5

@export var speed = 14
@export var fall_acceleration = 75
@export var jump_impulse = 20
@export var bounce_impulse = 16

var target_velocity = Vector3.ZERO

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		# velocity += get_gravity() * delta
		velocity.y -= fall_acceleration * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_impulse

	check_mob_collisions()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	velocity += target_velocity
	target_velocity = Vector3.ZERO

	if direction != Vector3.ZERO:
		$Pivot.basis = Basis.looking_at(direction)
		$AnimationPlayer.speed_scale = 4
	else:
		$AnimationPlayer.speed_scale = 1
	$Pivot.rotation.x = PI / 6 * velocity.y / jump_impulse

	move_and_slide()

func check_mob_collisions():
	for index in range(get_slide_collision_count()):
		var collision = get_slide_collision(index)
		var mob = collision.get_collider()
		if mob == null:
			continue
		if mob.is_in_group("mob"):
			if Vector3.UP.dot(collision.get_normal()) > 0.1:
				mob.squash()
				target_velocity.y = bounce_impulse
				break

func die():
	hit.emit()
	queue_free()


func _on_mob_detector_body_entered(body: Node3D) -> void:
	print("_on_mob_detector_body_enteredsa")
	die()
