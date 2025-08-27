extends ProjectileMod
class_name HomingMod

@export var homingRadius : float = 5
@export var homingStrength : float = 20

var homingRot : Vector3

func _ready():
	call_deferred("spawn_homing_area")


func spawn_homing_area() -> void:
	var homingArea : Area3D = Area3D.new()
	var collider : CollisionShape3D = CollisionShape3D.new()
	var shape : SphereShape3D = SphereShape3D.new()

	shape.radius = homingRadius

	get_parent().add_child(homingArea)
	homingArea.add_child(collider)
	collider.shape = shape

	homingArea.collision_layer = 0
	homingArea.set_collision_mask_value(2, true)
	homingArea.set_collision_mask_value(5, true)

	homingArea.body_entered.connect(homing_lock)


func homing_lock(body : Node3D) -> void:
	if action.target == null:
		if body != action.caster && action.entity_hit_filter(body):
			action.target = body


func _physics_process(delta : float):
	super(delta)
	if action.target:
		moveDir = (action.target.global_position - action.global_position).normalized()

		var rotationAmount = moveDir.cross(action.global_transform.basis.z)
		homingRot.y = rotationAmount.y * homingStrength * delta
		homingRot.x = rotationAmount.x * homingStrength * delta

		action.rotate(Vector3.UP, homingRot.y)
		action.rotate(Vector3.RIGHT, homingRot.x)
	