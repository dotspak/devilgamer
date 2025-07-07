extends CharSheet
class_name EnemySheet

@export_group("Statistical")
@export var mhpOverride : int = 0

@export_category("loot")
@export var gold : int = 100
@export var lootTable : Dictionary

@export_category("scripting")
@export var battleScript : GDScript = preload("res://src/units/enemyScript.gd")

func calc_mhp() -> float:
    if mhpOverride > 0: MHP = mhpOverride
    else: MHP = super()
    return MHP