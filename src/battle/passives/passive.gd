@icon("res://icons/passiveIcon.png")
extends Node
class_name Passive

@export var nextPassive : Passive
var isActive : bool = false
var entity : Entity

func setup(_entity : Entity) -> void:
    if _entity: entity = _entity
    else: return

func activate() -> void: isActive = true
func deActivate() -> void: isActive = false
func trigger_effect(_target : Entity) -> void: if !can_use(): return
func can_use() -> bool: return !isActive || !entity || entity.isDead