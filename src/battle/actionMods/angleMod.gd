extends ActionMod
class_name AngleMod

func set_action(_action : Action) -> void:
	await super(_action)

	var dir : Vector3 = Vector3.ZERO
	if action.target: dir = -(action.target.global_position - action.global_position).normalized()
	else: dir = -action.global_basis.z.normalized()
	action.look_at(action.global_position + dir, Vector3.UP)
