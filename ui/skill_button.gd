extends Button
class_name SkillButton

@export var ratingGrad : GradientTexture1D
var skill : Skill

func _ready(): unSelected()

# sets up the info of the button based on the passed skill
func setup(s : Skill) -> void:
	skill = s

	# set basic text and icon
	%icon.texture.region.position.x = skill.element * 16
	%name.text = skill.name
	%rank.text = str(skill.rating)

	# color the rating number
	var offset : float = clamp(skill.rating, 0, 10)
	offset /= 10
	var ratingColor : Color = ratingGrad.gradient.sample(offset / 10)
	%rank.label_settings.font_color = ratingColor
	%rank.label_settings.shadow_color = ratingColor / 0.5

func selected() -> void:
	var TW : Tween = create_tween()
	TW.tween_property($shadow, "color", Color.SALMON, 0.04)
	TW.tween_property($shadow, "color", Color.DARK_RED,0.06)

func unSelected() -> void: create_tween().tween_property($shadow, "color", Color(0.1,0.1,0.1), 0.1)
