extends Node3D

const FACES : Dictionary[String, int]= {
    "happy" : 3,
    "skull" : 4
}

@onready var anim : AnimationPlayer = %faceAnim
@onready var faceSprite : Sprite3D = %babyFace
var face : int = FACES["happy"]

func _ready(): face_change(FACES["happy"])
func _on_timer_timeout() -> void: face_change(face)
func face_change(newFace : int) -> void:
    $baby/Timer.stop()
    face = newFace
    anim.play("faceChange")
    await anim.animation_finished
    faceSprite.frame = face
    $baby/Timer.start()
