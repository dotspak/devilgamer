extends PlayerState

func enter() -> void:
	player.sounds["jump"].play()
	player.sounds["jump"].pitch_scale = randf_range(2, 2.5)
	player.model.jump()
	player = GameManager.player

	if !player.velocity.is_equal_approx(Vector3.ZERO):
		player.velocity += player.lastMoveDir * player.jumpDist

	player.velocity.y = 0
	player.velocity.y += player.jumpStrength
	player.jump_particles()

	player.stairRayAhead.enabled = false
	player.stairRayDown.enabled = false


func physics_update(delta : float) -> void:
	player.movement_input()
	player.air_move(delta)
	player.apply_gravity(delta)
	if player.velocity.y < -0.1 && !player.is_on_floor() || Input.is_action_just_released("jump"):
		stateMachine.transition_to("fall")
	if player.ledge_detect(true):
		stateMachine.transition_to("onLedge")
