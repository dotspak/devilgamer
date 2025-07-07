extends Action
class_name Action_HitScan

@export_group("Hitscan Options")
@export var shotNode : PackedScene

func spawn(t : CharacterBody3D, c : Node3D = null) -> void:
	super(t, c)
	shoot()


# locks on to the target and places the hitbox at their location
func shoot() -> void:
	var targetPos : Vector3 = target.global_position
	var dir : Vector3 = (targetPos - global_position).normalized()
	var startPos : Vector3 = global_position + dir * 0.25

	var tracer : Node3D = shotNode.instantiate()
	add_child(tracer)
	tracer.global_position = startPos
	tracer.targetPos = targetPos
	tracer.look_at(targetPos)

	collider.global_position = targetPos


func stop() -> void:
	await get_tree().create_timer(0.1).timeout
	super()
