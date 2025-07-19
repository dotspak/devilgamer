extends Sprite3D

const FX : String = "[shake][font_size=64][bgcolor=black]"

@onready var label : RichTextLabel = %num
@onready var anim : AnimationPlayer = $AnimationPlayer

signal popupDone

func display_dmg(dmg : float, isHeal : bool = false, isCrit : bool = false, isWeak : bool = false, isRes : bool = false) -> void:
	var text : String = FX
	text += get_color(isHeal, isCrit)

	# add effectiveness tag
	if isWeak: text += "weak\n"
	elif isRes: text += "resist\n"

	# add dmg number
	text += str(int(dmg))

	label.text = text

	anim.play("display")
	await anim.animation_finished
	popupDone.emit()


# determines what color the text should be according to the dmg's parameters
func get_color(isHeal : bool = false, isCrit : bool = false) -> String:
	var fx : String = ""

	if isHeal: fx = "[color=0f3]"
	elif isCrit: fx = "[rainbow]"

	return fx