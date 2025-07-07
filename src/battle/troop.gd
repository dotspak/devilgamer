# troop.gd -----------------------------
# stores all the info related to a particular battle instance.
# passed to a battle scene to trigger a battle based on the
# provided info.
# eg) Enemies, Backgrounds, Scripts, etc.
@icon("res://icons/battleData.png")
extends Resource
class_name Troop

@export var enemies : Array[EnemySheet]
@export var environment : PackedScene