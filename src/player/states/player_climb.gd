extends PlayerState

func enter() -> void:
    player.model.edge_grab()
    player.velocity = Vector3.ZERO
    player.set_physics_process(true)

func physics_update(_delta : float) -> void:
    if !player.is_on_ladder() || Input.is_action_just_pressed("ui_cancel") || (
        player.moveInput.y > 0.5 && player.is_on_floor()):
            stateMachine.transition_to("fall")
            return
    
    player.climbable_controls()
    player.move_and_slide()
    