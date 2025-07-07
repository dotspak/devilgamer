extends Sprite3D
class_name InteractPopup

const INTERACT_TEXT : String = "[shake][font_size=48][bgcolor=black]"

@onready var animator : AnimationPlayer = $AnimationPlayer
@onready var label : RichTextLabel = $SubViewport/Control/Label
@onready var labelShadow : ColorRect = $SubViewport/Control/Label/bgThing

enum MODES {TALK, CHEST, SHOP}

func set_mode(mode : MODES = MODES.TALK, custom : String = "") -> void:
	label.text = INTERACT_TEXT
	if custom == "":
		match mode:
			MODES.TALK: label.text += "talk"
			MODES.CHEST: label.text += "open"
			MODES.SHOP: label.text += "shop"
	else:
		label.text += custom


func display() -> void: 
	animator.play("show")
	await animator.animation_finished

func remove() -> void:
	animator.play_backwards("show")
	await animator.animation_finished
	queue_free()
