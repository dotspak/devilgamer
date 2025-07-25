extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var terminal : Control = $terminal
	remove_child(terminal)
	GameManager.add_ui(terminal)

