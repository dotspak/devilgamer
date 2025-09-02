extends Node

@onready var header : RichTextLabel = %header
@onready var text : RichTextLabel = %terminalText

@onready var textInput : LineEdit = %playerInput
@onready var modelDisplayer : AnimationPlayer = %modelDisplayer

func _ready() -> void:
	clear_text()

	var terminal : Control = $terminal
	remove_child(terminal)
	GameManager.add_ui(terminal)
	GameManager.player.freeze()

	await intro_animation()

	enable_text_input()


func intro_animation() -> void:
	await get_tree().create_timer(1).timeout

	var TW : Tween = create_tween()
	TW.tween_property(header, "visible_ratio", 1, 1).from(0)
	await TW.finished
	await get_tree().create_timer(2).timeout

	await show_model()


func enable_text_input() -> void:
	textInput.text = ""
	textInput.show()
	textInput.grab_focus()


func disable_text_input() -> void:
	textInput.hide()
	textInput.release_focus()


func show_model() -> void:
	modelDisplayer.play("toggleVisibility")
	await modelDisplayer.animation_finished

func hide_model() -> void:
	modelDisplayer.play_backwards("toggleVisibility")
	await modelDisplayer.animation_finished


func clear_text() -> void: text.text = ""


# -------------------------------------------------
# Dialogue Manager Handling
# -------------------------------------------------
@onready var options : DialogueResponse
