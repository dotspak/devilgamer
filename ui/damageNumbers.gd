extends Node2D
class_name DamageNumber

@onready var label : Label = $label
@onready var anim : AnimationPlayer = $AnimationPlayer

func play_anim(isCrit : bool = false, elemMod : float = 1, isHeal : bool = false) -> void:
    $label.show()
    $critBlood.hide()
    $label/extraLabel.hide()

    if isHeal:
        $label.self_modulate = Color.LIME_GREEN
    else:
        if isCrit: $critBlood.show()
        if elemMod > 1:
            $label/extraLabel.text = "REACT"
            $label/extraLabel.show()
        elif elemMod < 1:
            $label/extraLabel.text = "RESIST"
            $label/extraLabel.show()

    anim.play("play")
    await anim.animation_finished
    queue_free()