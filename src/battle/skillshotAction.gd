# skillshotAction.gd ------------------------------------
# holds all logic related to skillshot attacks which don't
# need a target to use.
extends Action
class_name Action_Skillshot

@export var animationName : String
@export var animator : AnimationPlayer
@export var pierce : bool = false

func trigger_skill_shot(c : Node3D = null) -> void:
	caster = c
	animator.play(animationName)
	await animator.animation_finished
	stop()


func _on_action_collision(body : Node3D) -> void:
	if body != caster && !body is OWPlayer:
		print(body.name)
		if body is Entity:
			body.display_damage_num(randi_range(5, 20))
			if !pierce:
				stop()
