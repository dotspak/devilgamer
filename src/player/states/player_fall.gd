extends PlayerState

const FALL_SHAKE_STRENGTH : float = 0.02

func enter() -> void: 
    player.model.fall()

func physics_update(delta : float) -> void:
    player.movement_input()
    player.air_move(delta)
    player.apply_gravity(delta)

    if player.is_on_floor():
        player.land()
        stateMachine.transition_to("idle")
    
    if player.airTimer > 1: 
        player.fallingParticles.emitting = true
        fall_shake(player.airTimer * FALL_SHAKE_STRENGTH)
    
    if player.ledge_detect(true):
        stateMachine.transition_to("onLedge")
        
func fall_shake(strength : float) -> void:
    strength = min(strength, 0.2)
    player.camera.h_offset = randf_range(-strength, strength)
    player.camera.v_offset = randf_range(-strength, strength)

func exit() -> void:
    player.canGrabLedge = true
    player.camera.h_offset = 0
    player.camera.v_offset = 0
    player.fallingParticles.emitting = false
    player.airTimer = 0