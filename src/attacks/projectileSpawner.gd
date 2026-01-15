extends Node3D
class_name ProjectileSpawner

@export var isPlayerProjectile : bool = false
@export var rotationLocks: Vector3i = Vector3i.ZERO

var templates : Array[Node]

func _ready():
    for c in get_children():
        if c is Projectile:
            c.hide()
            templates.append(c)


func spawn_projectiles() -> void:
    for projectile in templates:
        if !projectile is Projectile: return
        var newProjectile : Projectile = projectile.duplicate(Node.DUPLICATE_USE_INSTANTIATION)
        
        newProjectile.top_level = true
        newProjectile.global_transform = projectile.global_transform
        newProjectile.setup(owner, isPlayerProjectile)


func aim_at(targetPos : Vector3) -> void:
    var prevRot : Vector3 = global_rotation
    look_at(targetPos, Vector3.UP)

    var newRot : Vector3 = global_rotation

    if rotationLocks.x > 0: newRot.x = prevRot.x
    if rotationLocks.y > 0: newRot.y = prevRot.y
    if rotationLocks.z > 0: newRot.z = prevRot.z

    global_rotation = newRot
