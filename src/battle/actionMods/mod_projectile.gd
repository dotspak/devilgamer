extends ActionMod
class_name ProjectileMod

@export var moveSpeed : float = 20
var moveDir : Vector3 = Vector3.ZERO

func set_action(_action : Action) -> void:
	super(_action)
	if action.target: moveDir = (action.target.global_position - action.global_position).normalized()
	else: moveDir = action.global_basis.z.normalized()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if !action: return
	action.global_translate(moveDir * moveSpeed * delta)
