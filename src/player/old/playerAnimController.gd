extends Node3D

@export var animTree : AnimationTree
@onready var player : OverworldPlayer = get_parent()

var lastFacingDir : Vector2

func _physics_process(_delta: float) -> void:
    var horiziontalVelocity : Vector2 = Vector2(player.velocity.x, player.velocity.z).normalized()
    if player.velocity != Vector3.ZERO: lastFacingDir = horiziontalVelocity
    
    animTree.set("parameters/run/blend_position", horiziontalVelocity)
    animTree.set("parameters/idle/blend_position", lastFacingDir)