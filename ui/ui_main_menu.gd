extends Control
class_name MainMenu

@onready var anim : AnimationPlayer = $AnimationPlayer
@onready var buttonLabel : RichTextLabel = %buttonLabel
@onready var objective : RichTextLabel = %currentObjective
@onready var areaName : RichTextLabel = %areaName
@onready var playTime : RichTextLabel = %playTime
@onready var money : RichTextLabel = %money

@onready var phoneScreen : SubViewport = %phoneScreenViewport

const BG : String = "[bgcolor=000]"

var isFullMenu : bool = false
var transitioning : bool = false

var phoneOption : Button = null

func _ready() -> void:
	hide()

	var buttonEffect : Callable = func(button : Node) -> void: 
		phoneOption = button
		buttonLabel.text = BG + "> " + button.name
	
	for n : Button in %selectables.get_children():
		n.focus_entered.connect(buttonEffect.bind(n))
		n.mouse_entered.connect(buttonEffect.bind(n))


func _input(_event: InputEvent) -> void:
	if !visible: return
	if !transitioning:
		# fun animations
		if Input.is_action_just_pressed("ui_left"):
			AudioManager.play_ui_sfx("cursor")
			anim.stop(true)
			anim.play("tapLeft")
		if Input.is_action_just_pressed("ui_right"):
			AudioManager.play_ui_sfx("cursor")
			anim.stop(true)
			anim.play("tapRight")
		if Input.is_action_just_pressed("ui_up"):
			AudioManager.play_ui_sfx("cursor")
			anim.stop(true)
			anim.play("tapUp")
		if Input.is_action_just_pressed("ui_down"):
			AudioManager.play_ui_sfx("cursor")
			anim.stop(true)
			anim.play("tapDown")

		# transition logic
		if !isFullMenu:
			if Input.is_action_just_pressed("ui_accept"):
				AudioManager.play_ui_sfx("confirm")
				isFullMenu = true
				phoneOption.release_focus()
				play_transition("fullScreenZoom")
			if Input.is_action_just_pressed("ui_cancel"):
				GameManager.display_menu()
		else:
			if Input.is_action_just_pressed("ui_cancel"):
				AudioManager.play_ui_sfx("cancel")
				await play_transition("fullScreenZoom", true)
				phoneOption.grab_focus()
				isFullMenu = false


func play_transition(animation : String = "show", backwards : bool = false) -> void:
	if anim.has_animation(animation):
		transitioning = true
		set_process_unhandled_input(false)
		anim.stop(true)
		if backwards: anim.play_backwards(animation)
		else: anim.play(animation)

		await anim.animation_finished
		set_process_unhandled_input(true)
		transitioning = false


func display() -> void:
	CameraManager.enable_menu_cam()
	await play_transition("show")
	%items.grab_focus()


func undisplay() -> void:
	CameraManager.enable_main_cam()
	%items.release_focus()
	await play_transition("show", true)

