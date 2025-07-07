extends PlayerState

func enter() -> void:
    player.stepParticles.emitting = false
    player.canGrabLedge = true
    player.model.idle()

    player.stairRayAhead.enabled = true
    player.stairRayDown.enabled = true

func physics_update(delta : float) -> void:
    player.ledge_detect()
    player.move(delta)
    if player.movement_input(): stateMachine.transition_to("run")
    elif !player.is_on_floor(): stateMachine.transition_to("fall")

    # handle attack inputs
    if player.can_basic_attack(): player.use_basic_attack()
    elif player.should_use_skill(): player.use_action(preload("res://scenes/actions/machineGun.tscn"))
