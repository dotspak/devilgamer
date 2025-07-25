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

func _ready() -> void:
	hide()

	var buttonEffect : Callable = func(butonName : String): buttonLabel.text = BG + "> " + butonName
	for n : Button in %selectables.get_children():
		n.focus_entered.connect(buttonEffect.bind(n.name))
		n.mouse_entered.connect(buttonEffect.bind(n.name))


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_left"):
		anim.stop(true)
		anim.play("tapLeft")
	if Input.is_action_just_pressed("ui_right"): 
		anim.stop(true)
		anim.play("tapRight")
	if Input.is_action_just_pressed("ui_up"): 
		anim.stop(true)
		anim.play("tapUp")
	if Input.is_action_just_pressed("ui_down"): 
		anim.stop(true)
		anim.play("tapDown")


func display() -> void:
	anim.play("show")
	CameraManager.enable_menu_cam()
	await anim.animation_finished
	%items.grab_focus()


func undisplay() -> void:
	CameraManager.enable_main_cam()
	anim.play_backwards("show")
	await anim.animation_finished