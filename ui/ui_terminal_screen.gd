extends CanvasLayer
class_name TerminalScreen

const E : String = "f00"
const W : String = "f60"

@export var SCRIPT : DialogueResource
@export var next_action: StringName = &"ui_accept"
@export var skip_action: StringName = &"ui_cancel"

@onready var header : RichTextLabel = %header
@onready var originalText : DialogueLabel = %terminalText
@onready var textContainer : VBoxContainer = %textContainer
@onready var textInput : LineEdit = %playerInput
@onready var modelDisplayer : AnimationPlayer = %modelDisplayer
@onready var terminal : Control = %terminal
@onready var border : Control = %border

@onready var bgs : AudioStreamPlayer = $bgs
@onready var bgm : AudioStreamPlayer = $bgm

@onready var options : DialogueResponsesMenu = %options

var states: Array = [self]
var is_waiting_for_input : bool = false
var dialogue_line : DialogueLine :
	set(value):
		if value:
			dialogue_line = value
			apply_dialogue_line()
	get:
		return dialogue_line

var will_hide_balloon : bool = false
var mutation_cooldown: Timer = Timer.new()

var currentText : DialogueLabel
var targetTitle : String = "test"
var inputtedText : String = ""
var isTyping : bool = false

signal introFinished

func _ready() -> void:
	if get_tree().current_scene == self:
		print("loaded as scene")
		GameManager.load_terminal(targetTitle)
		queue_free()

	clear_text()

	# If the responses menu doesn't have a next action set, use this one
	if options.next_action.is_empty():
		options.next_action = next_action
	
	mutation_cooldown.timeout.connect(_on_mutation_cooldown_timeout)
	add_child(mutation_cooldown)

	await intro_animation()
	trigger_terminal_scene()


func random_session_tag(times : int = 5) -> String:
	var finalString : String = ""
	while times > 0:
		times -= 1
		finalString += str(randi() % 10)
	return finalString


func _unhandled_input(_event: InputEvent) -> void:
	# Only the balloon is allowed to handle input while it's showing
	get_viewport().set_input_as_handled()


func intro_animation() -> void:
	header.visible_ratio = 0
	border.modulate.a = 0	

	await get_tree().create_timer(1.0).timeout

	var TW : Tween = create_tween()
	TW.tween_property(border, "modulate:a", 1, 0.5).from(0)
	TW.tween_property(header, "visible_ratio", 1, 1).from(0)

	play_audio(1, 0)

	await TW.finished
	await get_tree().create_timer(2).timeout

	introFinished.emit()


func play_audio(to : float, from : float) -> void:
	var tween : Tween = create_tween().set_parallel()
	tween.tween_property(bgs, "volume_linear", to, 0.5).from(from)
	tween.tween_property(bgm, "volume_linear", to, 0.5).from(from)

	if !bgs.playing: bgs.play()
	if !bgm.playing: bgm.play()


func close_terminal() -> void:
	play_audio(0, 1)

	var TW : Tween = create_tween()
	TW.tween_property(header, "visible_ratio", 0, 1).from(1)
	TW.tween_property(border, "modulate:a", 0, 0.5).from(1)

	clear_text()
	hide_model()
	await TW.finished


func load_next_area(area : int = GameManager.startingArea) -> void:
	GameManager.fadeout_screen(0)
	GameManager.player.un_freeze()
	GameManager.player.show()
	GameManager.areaLoaded.connect(queue_free)
	GameManager.load_area(area, "", Color.BLACK)


func trigger_terminal_scene() -> void: 
	print("attempting to start terminal scene with title: ", targetTitle)
	call_deferred("start")

# region Controls
func enable_text_input() -> void:
	isTyping = true
	textInput.show()
	textInput.editable = true
	terminal.focus_mode = Control.FOCUS_NONE
	textInput.focus_mode = Control.FOCUS_ALL
	textInput.grab_focus()


func disable_text_input() -> void:
	isTyping = false
	textInput.text = ""
	textInput.editable = false
	textInput.focus_mode = Control.FOCUS_NONE
	textInput.release_focus()
	textInput.hide()


func player_text_input() -> void:
	if isTyping: return
	enable_text_input()
	textInput.text = ""
	inputtedText = await textInput.text_submitted
	inputtedText = inputtedText.split("\n")[0]
	disable_text_input()


func get_inputted_text() -> String:
	print(textInput.text)
	return inputtedText


func show_model() -> void:
	modelDisplayer.play("toggleVisibility")
	await modelDisplayer.animation_finished

func hide_model() -> void:
	modelDisplayer.play_backwards("toggleVisibility")
	await modelDisplayer.animation_finished


func clear_text() -> void:
	for n : DialogueLabel in textContainer.get_children():
		var tween : Tween = create_tween()
		tween.tween_property(n, "visible_ratio", 0, 0.3)
		tween.finished.connect(n.queue_free)
	
	await get_tree().create_timer(0.4).timeout

# endregion


# region Dialogue


func start() -> void: 
	self.dialogue_line = await SCRIPT.get_next_dialogue_line(targetTitle, states)
	is_waiting_for_input = false

	DialogueManager.dialogue_started.emit(SCRIPT)
	DialogueManager.bridge_dialogue_started.emit(SCRIPT)

func next(next_id : String) -> void: 
	dialogue_line = await SCRIPT.get_next_dialogue_line(next_id, states)

func _on_terminal_gui_input(event: InputEvent) -> void:
	if !currentText: return

	# See if we need to skip typing of the dialogue
	if currentText.is_typing && !isTyping:
		var mouse_was_clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()
		var skip_button_was_pressed: bool = event.is_action_pressed(skip_action)
		if mouse_was_clicked or skip_button_was_pressed:
			get_viewport().set_input_as_handled()
			currentText.skip_typing()
			return

	if not is_waiting_for_input: return
	if dialogue_line.responses.size() > 0: return

	# When there are no response options the balloon itself is the clickable thing
	get_viewport().set_input_as_handled()

	if !isTyping:
		if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
			next(dialogue_line.next_id)
		elif event.is_action_pressed(next_action) and get_viewport().gui_get_focus_owner() == terminal:
			next(dialogue_line.next_id)


func _on_terminal_text_spoke(letter: String, _letter_index: int, _speed: float) -> void:
	if !letter in [">"]: 
		AudioManager.play_talk_sfx("Terminal")

func _on_options_response_selected(response: DialogueResponse) -> void: next(response.next_id)

func apply_dialogue_line() -> void:
	currentText = originalText.duplicate()
	currentText.text = ""
	textContainer.add_child(currentText)
	currentText.show()

	mutation_cooldown.stop()

	is_waiting_for_input = false
	if !textInput.visible:
		terminal.focus_mode = Control.FOCUS_ALL
		terminal.grab_focus()

	options.hide()
	options.responses = dialogue_line.responses

	currentText.hide()
	currentText.dialogue_line = dialogue_line

	# Show our balloon
	terminal.show()
	will_hide_balloon = false

	currentText.show()
	if not dialogue_line.text.is_empty():
		currentText.type_out()
		await currentText.finished_typing

	# Wait for input
	if dialogue_line.responses.size() > 0:
		terminal.focus_mode = Control.FOCUS_NONE
		options.show()
	elif dialogue_line.time != "":
		var time = dialogue_line.text.length() * 0.02 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
		await get_tree().create_timer(time).timeout
		next(dialogue_line.next_id)
	else:
		is_waiting_for_input = true
		terminal.focus_mode = Control.FOCUS_ALL
		terminal.grab_focus()


func _on_mutation_cooldown_timeout() -> void:
	if will_hide_balloon:
		will_hide_balloon = false
		terminal.hide()


func _on_mutated(_mutation: Dictionary) -> void:
	is_waiting_for_input = false
	will_hide_balloon = true
	mutation_cooldown.start(0.1)

# endregion
