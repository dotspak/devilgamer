@tool
@icon("res://icons/roomTransitionIcon.png")
extends RoomInstance
class_name RoomToArea

signal areaTransitionEntered(area : String)

@export var toArea : String
@export var spawnPoint : Node3D
@export var transitionTrigger : Area3D

func _ready() -> void:
	transitionTrigger.body_entered.connect(_transition_entered)

func _transition_entered(body : Node3D) -> void:
	if body is OWPlayer:
		areaTransitionEntered.emit(toArea)
