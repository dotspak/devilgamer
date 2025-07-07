# KillPlane.gd
# Makes the player respawn when passing by this area
extends Area3D
class_name KillPlane

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void: if body is OWPlayer: body.respawn() 
