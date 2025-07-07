@tool
extends CharacterBody3D
class_name Interactable

const POPUP_SCENE : PackedScene = preload("res://ui/dialogue/ui_popupBalloon.tscn")
var popup : InteractPopup

@export var interactArea : Area3D :
	set(val):
		interactArea = val
		interactArea.add_to_group("interactable")
@export var popupPos : Marker3D

@export_group("Cutscene details")
@export var interactableType : InteractPopup.MODES = InteractPopup.MODES.TALK
@export var customTypeText : String = ""
@export var dialogueResource : DialogueResource
@export var startingTitle : String = "start"

signal interactionBegin
signal interactionFinished

func _ready():
	print(name)
	interactArea.collision_mask = 2
	interactArea.collision_layer = 4
	
	interactArea.body_entered.connect(display_interact_bubble)
	interactArea.body_exited.connect(hide_interact_bubble)


func orient_player_to_interaction() -> void:
	if !GameManager.player: return
	
	var playerPos : Vector3 = GameManager.player.global_position
	var dir : Vector3 = (global_position - playerPos).normalized()
	dir.y = 0
	GameManager.player.lastMoveDir = (dir)


func run_interaction() -> void:
	interactionBegin.emit()
	GameManager.hide_battle_ui()

	# face the player to the npc
	orient_player_to_interaction()

	# creates the camera that shows player and npc
	var camera : PhantomCamera3D = CameraManager.create_conversation_camera(self)
	CameraManager.set_active_cam(camera)

	# run the dialogue of the npc
	if dialogueResource:
		GameManager.create_dialogue_window(dialogueResource, startingTitle)
		GameManager.player.disable_input()
		await DialogueManager.dialogue_ended
	else:
		# just for error handling
		await get_tree().create_timer(0.2).timeout
	
	# final scene clean up
	CameraManager.enable_main_cam()
	GameManager.player.enable_input()
	camera.queue_free()
	interactionFinished.emit()
	GameManager.show_battle_ui()


func display_interact_bubble(body : Node3D) -> void:
	if body is OWPlayer && body.is_on_floor():
		popup = POPUP_SCENE.instantiate()
		popupPos.add_child(popup)
		popup.set_mode(interactableType, customTypeText.to_lower())


func hide_interact_bubble(body : Node3D) -> void:
	if body is OWPlayer:
		if popup:
			popup.remove()
			popup = null
