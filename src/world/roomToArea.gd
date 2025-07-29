@tool
@icon("res://icons/roomTransitionIcon.png")
extends RoomInstance
class_name RoomToArea

signal areaTransitionEntered(area : String, playerPos : Vector3)

@export var toArea : String
@export var spawnPoint : Node3D
@export var transitionTrigger : Area3D
@export var playerWalkToPos : Marker3D
@export var areaCam : PhantomCamera3D

func _ready() -> void:
	if !areaCam:
		for n : Node in get_children(true):
			if n is PhantomCamera3D:
				areaCam = n
	
	if transitionTrigger:
		transitionTrigger.body_entered.connect(_transition_entered)


func _transition_entered(body : Node3D) -> void:
	if body is OWPlayer:
		var playerPos : Vector3 = playerWalkToPos.global_position if playerWalkToPos else GameManager.player.global_position
		CameraManager.set_active_cam(areaCam, AreaInstance.AREA_FADE_TIME)
		areaTransitionEntered.emit(toArea, playerPos)
