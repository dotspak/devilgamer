extends PlayerState

var stepTimer : float = 0

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
	
	if Input.is_action_just_pressed("action"):
		stateMachine.transition_to("roll")
	
	if player.is_on_ladder():
		var camForward = -player.camera.global_basis.z
		camForward.y = 0
		camForward = camForward.normalized()

	player.move(delta)

	if player.jump_check(): stateMachine.transition_to("jump")
	
	if !player.is_on_floor():
		if !player.stairRayDown.is_colliding():
			stateMachine.transition_to("fall")
		return
	else:
		if player.model.get_current_anim() != "run":
			player.model.move()


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
