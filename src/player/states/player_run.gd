extends PlayerState

var ledgeTimer : float = 0
var stepTimer : float = 0
const LEDGE_WAIT : float = 0.25

func enter() -> void:
	player.model.move()
	player.stepParticles.emitting = true

	player.stairRayAhead.enabled = true
	player.stairRayDown.enabled = true


func physics_update(delta : float) -> void:
	footsteps(delta)

	if !player.movement_input(): 
		stateMachine.transition_to("idle")
		return
	
	if player.is_on_ladder():
		var camForward = -player.camera.global_basis.z
		camForward.y = 0
		camForward = camForward.normalized()

	player.move(delta)    
	
	if !player.is_on_floor():
		if player.jump_check(): 
			stateMachine.transition_to("jump")
		elif !player.stairRayDown.is_colliding():
			stateMachine.transition_to("fall")
		return
	
	if player.ledge_detect():
		ledgeTimer += delta
		if ledgeTimer >= LEDGE_WAIT:
			ledgeTimer = 0
			stateMachine.transition_to("jumpToLedge")
	else:
		ledgeTimer = max(ledgeTimer - delta, 0)
	
	if player.can_basic_attack():
		player.use_basic_attack()
	elif player.should_use_skill():
		player.use_action(preload("res://scenes/actions/machineGun.tscn"))


func exit() -> void: 
	player.stepParticles.emitting = false


func footsteps(delta : float) -> void:
	stepTimer += delta
	if stepTimer > 0.28:
		if player.is_underwater():
			player.sounds["waterStep"].pitch_scale = randf_range(0.9, 1.1)
			player.sounds["waterStep"].play()
			stepTimer = 0
		else:
			player.sounds["step"].pitch_scale = randf_range(0.9, 1.1)
			player.sounds["step"].play()
			stepTimer = 0
