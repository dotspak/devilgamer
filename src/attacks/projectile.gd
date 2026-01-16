extends Node3D
class_name Projectile

@export var speed : float = 10.0
@export var lifetime : float = 3.0
@export var pierces : bool = false

@export_group("Stat Parameters")
@export var damage : float = 10.0
@export var attackMult : float = 0.5
@export var element : GameConstants.Elements = GameConstants.Elements.None

@onready var hitbox : Area3D = $Hitbox

var dir : Vector3 = Vector3.FORWARD
var isPlayerProjectile : bool = false

func _ready():
    if hitbox:
        hitbox.body_entered.connect(_on_body_entered)


func setup(_owner : Node, _isPlayerProjectile : bool) -> void:
    owner = _owner
    isPlayerProjectile = _isPlayerProjectile

    var t : Timer = Timer.new()
    t.one_shot = true
    t.wait_time = lifetime
    t.timeout.connect(destroy)
    add_child(t)
    t.start()

    show()


func _physics_process(delta : float) -> void:
    if visible:
        global_position += (-global_basis.z) * speed * delta


func _on_body_entered(body : Node) -> void:
    if body == owner: return
    if (isPlayerProjectile && body.is_in_group("player")) || (!isPlayerProjectile && !body.is_in_group("player")): return
    if body is Entity:
        var attack : float = (owner.get_attack_stat() if owner && owner is Entity else 0) * attackMult
        body.take_damage(attack + damage)

        if !pierces: destroy()
    else:
        destroy()


func destroy() -> void: queue_free()