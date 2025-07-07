extends Node3D
class_name SkillAnim

@onready var anim : AnimationPlayer = $AnimationPlayer

enum ANIM_TYPE {single, screen}
@export var animType : ANIM_TYPE = ANIM_TYPE.single
var skill : Skill

signal finished

func _ready(): anim.animation_finished.connect(finished.emit)
func play() -> void: anim.play("spawn")
func trigger_dmg(all : bool = false) -> void: skill.handle_damage(all)
func ending() -> void: await get_tree().create_timer(0.4).timeout
func pause() -> void: await get_tree().create_timer(0.1).timeout
