extends CanvasGroup
class_name BattlePuppet

# outline colors
const DEF_OUTLINE : Color = Color(0.5,0,0)
const WEAK_OUTLINE : Color = Color.GOLD
const RES_OUTLINE : Color = Color.GRAY
const MAX_THICK : int = 3

var current_thickness : float = 0
var def_pos : Vector2
var anim : AnimationPlayer

func _ready() -> void:
	anim = get_node_or_null("AnimationPlayer")
	def_pos = position
	
	material = load("res://shaders/puppetMaterial.tres").duplicate()
	material.resource_local_to_scene = true
	material.set("shader_parameter/line_colour", DEF_OUTLINE)
	hide_outline()

# sets the outline, used for tweens
func set_outline(val : float) -> void: 
	current_thickness = val
	material.set("shader_parameter/line_thickness", current_thickness)

func show_outline(color : Color) -> void:
	material.set("shader_parameter/line_colour", color)
	create_tween().tween_method(set_outline, current_thickness, MAX_THICK, 0.2)

func hide_outline() -> void: create_tween().tween_method(set_outline, current_thickness, 0, 0.2)

# plays the puppet's damage animation
func play_damage_anim() -> void:
	if anim && anim.has_animation("damage"): 
		anim.play("damage")
		await anim.animation_finished
		idle_anim()
	else: # backup animation
		var TW : Tween = create_tween()
		TW.tween_property(self, "position:x", def_pos.x + 5, 0.1).from(def_pos.x)
		TW.tween_property(self, "position:x", def_pos.x - 5, 0.1)
		TW.tween_property(self, "position:x", def_pos.x, 0.1)
		await TW.finished

# plays the puppet's casting animation. If the puppet has a specific animation
# for the passed skill, play that instead
func play_cast_anim(skill : Skill) -> void:
	if anim:
		if anim.has_animation("cast_" + skill.name):
			anim.play("cast_" + skill.name)
			await anim.animation_finished
			idle_anim()
		elif anim.has_animation("cast"):
			anim.play("cast")
			await anim.animation_finished
			idle_anim()
	else: # backup animation
		var bright : Color = Color(4,4,4)
		var TW : Tween = create_tween()
		TW.tween_property(self, "self_modulate", bright, 0.1)
		TW.tween_property(self, "self_modulate", Color.BLACK, 0.1)
		TW.tween_property(self, "self_modulate", bright, 0.1)
		TW.tween_property(self, "self_modulate", Color.BLACK, 0.1)
		TW.tween_property(self, "self_modulate", bright, 0.1)
		TW.tween_property(self, "self_modulate", Color.WHITE, 0.1)
		await TW.finished
	
func play_death_anim() -> void:
	if anim && anim.has_animation("death"):
		anim.play("death")
		await anim.animation_finished
	else:
		var TW : Tween = create_tween()
		TW.tween_property(self, "scale", Vector2.ZERO, 0.2)
		await TW.finished
	
func play_revive_anim() -> void:
	if anim && anim.has_animation("death"):
		anim.play_backwards("death")
		await anim.animation_finished
	else:
		var TW : Tween = create_tween()
		TW.tween_property(self, "scale", Vector2.ONE, 0.2)
		await TW.finished

# temporary, do animation trees instead
func idle_anim() -> void: if anim && anim.has_animation("idle"): anim.play("idle")

func get_bounding_box() -> Vector2:
	var bounds : Vector2 = Vector2.ZERO

	return bounds