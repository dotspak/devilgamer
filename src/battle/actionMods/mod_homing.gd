extends ProjectileMod
class_name HomingMod

@export var homingStrength : float = 20
var homingRot : Vector3

func _physics_process(delta : float):
	super(delta)
	if action.target:
		moveDir = (action.target.global_position - action.global_position).normalized()

		var rotationAmount = moveDir.cross(action.global_transform.basis.z)
		homingRot.y = rotationAmount.y * homingStrength * delta
		homingRot.x = rotationAmount.x * homingStrength * delta

		action.rotate(Vector3.UP, homingRot.y)
		action.rotate(Vector3.RIGHT, homingRot.x)
	