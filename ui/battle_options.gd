extends Control
class_name BattleOptions

const skillButton : PackedScene = preload("res://ui/skillButton.tscn")

var actor : Unit
var cursorPath : NodePath

@onready var defpos : Vector2 = position
@onready var items : VBoxContainer = $vbox/items

signal finished

func clear_skills() -> void: for n : Node in items.get_children(): n.queue_free()
func spawn_skills(a : Unit) -> void:
	# remove any skills previously there
	clear_skills()
	actor = a
	
	# spawn the skill buttons
	for s : Skill in actor.skillList:
		var b : SkillButton = skillButton.instantiate()
		b.setup(s)
		items.add_child(b)

		var TW : Tween = create_tween().set_trans(Tween.TRANS_BACK)
		TW.tween_property(b, "position:x", 0, 0.1).from(b.position.x - 20)
		await get_tree().create_timer(0.05).timeout
	await get_tree().create_timer(0.05).timeout

	_on_optionChanged(0)
	spawn_cursor()
	
# displays the options
func show_options() -> void:
	var TW : Tween = create_tween()
	TW.tween_property(self, "position:x", defpos.x, 0.1).from(defpos.x - size.x)
	await TW.finished

# hides the skill options
func hide_options() -> void:
	var TW : Tween = create_tween()
	TW.tween_property(self, "position:x", defpos.x - size.x, 0.1)
	actor = null
	despawn_cursor()
	await TW.finished

# handles when a new option is selected
func _on_optionChanged(idx : int) -> void:
	idx = clamp(idx, 0, items.get_child_count() - 1)
	var skill : Skill = items.get_child(idx).skill
	GameManager.battleScene.show_bottom_text(skill.description)

# handles when an option is selected
func _on_optionSelected(idx : int) -> void:
	idx = clamp(idx, 0, items.get_child_count() - 1)
	actor.selectedSkill = items.get_child(idx).skill
	finished.emit()
	despawn_cursor()

func spawn_cursor() -> void: cursorPath = GameManager.spawn_cursor(self, items, _on_optionChanged, _on_optionSelected, Vector2(size.x - 24, 4))
func despawn_cursor() -> void: GameManager.despawn_cursor(cursorPath)
