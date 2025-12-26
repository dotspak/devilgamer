extends PlayerState

var rollFinished : bool = false
var TW : Tween

func enter() -> void:
	rollFinished = false
	player.sounds["roll"].play()
	player.sounds["roll"].pitch_scale = randf_range(0.8, 1.2)
	player.model.roll()

	TW = create_tween().set_trans(Tween.TRANS_SINE)
	var dir : Vector3 = player.lastMoveDir.normalized()
	var finalVel : Vector3 = player.velocity

	player.model.rotation.y = Vector3.BACK.signed_angle_to(dir, Vector3.UP)
	player.velocity = Vector3.ZERO
	TW.tween_property(player, "velocity", dir * player.rollSpeed, 0.1).set_ease(Tween.EASE_IN)
	TW.tween_property(player, "velocity", finalVel, 0.3).set_ease(Tween.EASE_OUT)

	await TW.finished

	rollFinished = true


func physics_update(_delta: float):
	if player.jump_check():
		TW.kill()
		print("roll to jump")
		player.velocity = player.lastMoveDir * player.rollSpeed * 0.5
		stateMachine.transition_to("jump")
	if rollFinished: stateMachine.transition_to("run")
