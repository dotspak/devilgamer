# boot.gd -------------------------------------
# runs whenever the game is opened, usually for loading the title screen.
extends Node

@onready var splashes : CanvasLayer = $introSplash

func _ready() -> void:
	await splashes.play_splashes()
	splashes.queue_free()
	spawn_title()

func spawn_title() -> void:
	var title : Control = load("res://scenes/titleScreen.tscn").instantiate()
	var scene : Node3D = load("res://scenes/titleScreenScenes/emptyWorld.tscn").instantiate()

	add_child(scene)

	GameManager.add_ui(title)
	GameManager.fadein_screen()
	CameraManager.set_active_cam(scene.find_child("Node3D").get_child(0), 0)
	GameManager.player.freeze()
	GameManager.player.hide()

	await get_tree().process_frame

	scene.find_child("Camera3D").make_current()
