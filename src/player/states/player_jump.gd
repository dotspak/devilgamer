extends PlayerState

func enter() -> void:
    player.model.jump()
    player = GameManager.player
    if !player.velocity.is_equal_approx(Vector3.ZERO):
        player.velocity += player.lastMoveDir * player.jumpDist
    player.velocity.y += player.jumpStrength
    player.jump_particles()

    player.stairRayAhead.enabled = false
    player.stairRayDown.enabled = false


func physics_update(delta : float) -> void:
    player.movement_input()
    player.air_move(delta)
    player.apply_gravity(delta)
    if player.velocity.y <= 0 || Input.is_action_just_released("jump"):
        player.velocity.y = 0
        stateMachine.transition_to("fall")
    if player.ledge_detect(true):
        stateMachine.transition_to("onLedge")