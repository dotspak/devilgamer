# skillshotAction.gd ------------------------------------
# holds all logic related to skillshot attacks which don't
# need a target to use.
extends Action
class_name Action_Skillshot

@export var animationName : String
@export var animator : AnimationPlayer
@export var timeToLive : Timer
@export var destroyOnCollision : bool = true

func trigger_skill_shot(c : Node3D = null) -> void:
	caster = c
	if animator:
		animator.play(animationName)
		await animator.animation_finished
	elif timeToLive:
		timeToLive.start()
		await timeToLive.timeout
	else:
		await get_tree().create_timer(1.0).timeout
	stop()


func _on_action_collision(body : Node3D) -> void:
	if body != caster && !body is OWPlayer:
		print(body.name)
		if body is Entity:
			entity_hit(body)
			if !destroyOnCollision:
				stop()
