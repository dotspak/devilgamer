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

	if player.jump_check(): stateMachine.transition_to("jump")

	
	# epia camera look easter egg
	if Input.is_anything_pressed():
		if player.mainCam.spring_length != player.defaultSpringLength:
			player.model.idle()
			player.change_zoom(1, 0.2)
			create_tween().tween_property(player.mainCam, "follow_offset:y", player.defaultCamOffset.y, 0.2)
			if player.model is EpiaSkin:
				if !player.model.cameraEggTimer.is_stopped():
					player.model.cameraEggTimer.stop()
					player.model.cameraEggTimer.timeout.disconnect(player.camera_look_egg)
		else:
			if player.model is EpiaSkin:
				if player.model.cameraEggTimer.is_stopped():
					player.model.cameraEggTimer.start()
					player.model.cameraEggTimer.timeout.connect(player.camera_look_egg)
