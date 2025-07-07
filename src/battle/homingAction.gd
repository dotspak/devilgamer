# homingAction.gd ------------------------------------
# holds all logic related to homing attack based skills
extends Action
class_name Action_Homing

@export_group("Homing Options")
@export var rotationSpeed : float = 20
@export var speed : float = 10
@export var lockDur : float = 0.5

var velocity : Vector3 = Vector3.ZERO
var rot : Vector3 = Vector3.ZERO

func _ready():
    super()
    get_tree().create_timer(lockDur).timeout.connect(emit_signal.bind("actionFinished"))

func _physics_process(delta: float) -> void:
    if !target: return

    var dir : Vector3 = target.global_position - global_transform.origin
    dir = dir.normalized()

    var rotationAmount = dir.cross(global_transform.basis.z)
    rot.y = rotationAmount.y * rotationSpeed * delta
    rot.x = rotationAmount.x * rotationSpeed * delta

    rotate(Vector3.UP, rot.y)
    rotate(Vector3.RIGHT, rot.x)

    global_translate(-global_basis.z * speed * delta)