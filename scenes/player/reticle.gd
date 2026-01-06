extends Node3D
class_name Reticle

@onready var sprite : Sprite3D = $Sprite3D

func _ready(): lock_off()
func set_active(active : bool = true) -> void: visible = active
func set_world_pos(pos : Vector3 = Vector3.ZERO) -> void: global_position = pos
func lock_on() -> void: sprite.modulate = Color.ORANGE
func lock_off() -> void: sprite.modulate = Color.PALE_VIOLET_RED