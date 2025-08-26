extends PlayerState

func enter() -> void:
    player.stepParticles.emitting = false
    player.model.idle()

    player.stairRayAhead.enabled = true
    player.stairRayDown.enabled = true

func physics_update(delta : float) -> void:
    player.ledge_detect()
    player.move(delta)

    if player.movement_input(): stateMachine.transition_to("run")
    elif !player.is_on_floor(): stateMachine.transition_to("fall")

    elif Input.is_action_just_pressed("action"):
        stateMachine.transition_to("roll")
