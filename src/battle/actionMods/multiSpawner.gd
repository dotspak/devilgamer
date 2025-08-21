extends ActionMod
class_name MultiSpawner

@export var bonusActions : Array[Action]

func _ready() -> void:
	await actionSet
	call_deferred("setup")
	
func setup() -> void:
	for a : Action in bonusActions:
		a.spawn(action.caster, action.target)
		if !a.skill: a.skill = action.skill
