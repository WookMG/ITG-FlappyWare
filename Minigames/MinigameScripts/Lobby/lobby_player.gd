extends MultiplayerBase

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	var jump_input = Input.is_action_just_pressed("Jump")
	if idle:
		position.y += 0.5 * sin(Time.get_ticks_msec()/500.0)
		if jump_input:
			jump()
			idle = false
			set_collision_layer_value(2, true)
			show_body()
	else:
		if !is_on_floor():
			velocity += get_gravity() * delta
			move()
		else:
			velocity.y = 0
			deccelerate()
		if is_on_wall(): bounce()
		if is_on_ceiling() and velocity.y < 0: velocity.y = -velocity.y
		elif jump_input: jump()
	lastVelocity = velocity
	head.rotation = speed_to_rotation(velocity.y)
	move_and_slide()

func bounce() -> void:
	if !isFacingLeft and lastVelocity.x > 0:
		isFacingLeft = true
		head.flip_h = isFacingLeft
		velocity.x =- lastVelocity.x / WALL_ABSORBTION
	elif isFacingLeft and lastVelocity.x < 0:
		isFacingLeft = false
		head.flip_h = isFacingLeft
		velocity.x =- lastVelocity.x / WALL_ABSORBTION

@rpc("any_peer", "call_local", "reliable")
func hit_pipe() -> void:
	idle = true
	set_collision_layer_value(2, false)
	set_worm_properties()
	head.rotation = 0
	velocity = Vector2.ZERO
