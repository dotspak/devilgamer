extends PlayerState

func enter() -> void:
	player.calc_jump()
	player.sounds["jump"].play()
	player.sounds["jump"].pitch_scale = randf_range(2, 2.5)
	player.model.jump()

	#if !player.velocity.is_equal_approx(Vector3.ZERO):
	#	player.velocity += player.lastMoveDir * player.jumpDist

	player.velocity.y = player.jumpVelocity
	player.jump_particles()

	player.stairRayAhead.enabled = false
	player.stairRayDown.enabled = false


func physics_update(delta : float) -> void:
	player.movement_input()
	player.air_move(delta)
	player.apply_gravity(delta)
	
	if (player.velocity.y <= 0 && !player.is_on_floor()) || Input.is_action_just_released("jump"):
		stateMachine.transition_to("fall")
	if player.ledge_detect(true):
		stateMachine.transition_to("onLedge")
