extends PlayerState

func enter() -> void:
	player.model.roll()

	var TW : Tween = create_tween().set_trans(Tween.TRANS_SINE)
	var dir : Vector3 = player.lastMoveDir.normalized()
	var finalVel : Vector3 = player.velocity

	player.velocity = Vector3.ZERO
	TW.tween_property(player, "velocity", dir * player.rollSpeed, 0.1).set_ease(Tween.EASE_IN)
	TW.tween_property(player, "velocity", finalVel, 0.3).set_ease(Tween.EASE_OUT)
	await TW.finished  

	stateMachine.transition_to("run")
