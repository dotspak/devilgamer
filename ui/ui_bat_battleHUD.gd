extends Control
class_name BattleHUD

const DMG_NUMS : PackedScene = preload("res://ui/damageNumbers.tscn")
const ACTOR_HUD : PackedScene = preload("res://ui/ui_bat_actorHud.tscn")

const TOP_TEXT_SHOW : float = 16
const TOP_TEXT_HIDE : float = -48
const BOT_TEXT_SHOW : float = 464
const BOT_TEXT_HIDE : float = 512

@onready var battleOptions : BattleMenu = %battleOptions
@onready var actorHuds : VBoxContainer = %actorHuds
@onready var bottomText : RichTextLabel = %bottomLabel
@onready var topText : RichTextLabel = %topLabel
@onready var stateMachine : StateMachine = %hudStates
@onready var guardEffect : Control = %guard

var previousState : String = ""
var skillDisplay : bool = true
var cursorPath : NodePath = ""
var currentActor : Actor
var hudRef : Dictionary

func _ready():
	hide_top_text()
	bottomText.text = ""
	topText.text = ""


func setup(actors : Array[Actor]) -> void:
	battleOptions.HUD = self
	spawn_actor_huds(actors)
	currentActor = actors[0]
	currentActor.battleTimer.paused = false
	stateMachine.transition_to("default")


# spawns the huds for the members in the party
func spawn_actor_huds(actors : Array[Actor]) -> void:
	clear_actor_huds()
	for a : Actor in actors:
		var hud : ActorHud = ACTOR_HUD.instantiate()
		hudRef[a] = hud
		actorHuds.add_child(hud)
		hud.actor = a


func handle_actor_death(actor : Actor) -> void:
	if actor == currentActor:
		pass


# shows top text as an animation
func display_top_text(text : String = "", duration : float = 1.0, elem : int = -1) -> void:
	await show_top_text(text, elem)
	await get_tree().create_timer(duration).timeout
	await hide_top_text()


# shows top text and keeps it there
func show_top_text(text : String = "", elem : int = -1) -> void:
	if elem >= 0: 
		%elemIcon.show()
		create_tween().tween_property(%elemIcon, "texture:region:position:x", elem * 16, 0.1)
	else:
		%elemIcon.hide()
	if text != "": topText.text = "[center]" + text
	
	var TW = create_tween().set_trans(Tween.TRANS_BACK)
	TW.tween_property(topText.get_parent(), "position:y", TOP_TEXT_SHOW, 0.2)
	await TW.finished


# manually hides top text
func hide_top_text() -> void:
	var TW = create_tween()
	TW.tween_property(topText.get_parent(), "position:y", TOP_TEXT_HIDE, 0.1)
	await TW.finished


# shows bottom text as an animation
func display_bottom_text(text : String = "", duration : float = 1.0) -> void:
	await show_bottom_text(text)
	await get_tree().create_timer(duration).timeout
	await hide_bottom_text()


# shows bottom text and keeps it there
func show_bottom_text(text : String = "") -> void:
	if text != "": bottomText.text = "[center]" + text
	var TW = create_tween().set_trans(Tween.TRANS_BACK).set_parallel(true)
	TW.tween_property(bottomText.get_parent(), "position:y", BOT_TEXT_SHOW, 0.3)
	TW.tween_property(bottomText, "visible_ratio", 1, bottomText.text.length() * 0.015).from(0).set_trans(Tween.TRANS_LINEAR)
	await TW.finished


# manually hides bottom text
func hide_bottom_text() -> void:
	var TW = create_tween()
	TW.tween_property(bottomText.get_parent(), "position:y", BOT_TEXT_HIDE, 0.1)
	await TW.finished


# handles when a new option is selected
func _on_optionChanged(IDX : int) -> void:
	IDX = clamp(IDX, 0, battleOptions.items.get_child_count() - 1)

	if battleOptions.items.get_child_count() > battleOptions.menuIDX:
		battleOptions.items.get_child(battleOptions.menuIDX).unSelected()
	battleOptions.items.get_child(IDX).selected()
	battleOptions.scroll_control(IDX)

	battleOptions.menuIDX = IDX

	if stateMachine.get_state() == "default":
		var skill : Skill = battleOptions.items.get_child(IDX).skill
		show_bottom_text(skill.description)
	


# handles when an option is selected
func _on_optionSelected(idx : int) -> void:
	if currentActor.phase != Unit.Phase.SELECTING: return
	
	idx = clamp(idx, 0, battleOptions.items.get_child_count() - 1)
	if stateMachine.get_state() == "default":
		currentActor.selectedSkill = battleOptions.items.get_child(idx).skill
		stateMachine.transition_to("unitSelect")
	elif stateMachine.get_state() == "unitSelect":
		currentActor.target.clear()
		currentActor.target.append_array(battleOptions.items.get_child(idx).units)
		currentActor.enter_casting_phase()
		currentActor = GameManager.battleScene.formation.get_actor(
			GameManager.battleScene.formation.get_next_actor_idx(currentActor))
		stateMachine.transition_to("default")
	despawn_cursor()


# spawns the buttons for the skills of the current actor
func spawn_skills() -> void:
	despawn_cursor()
	await battleOptions.spawn_skills(currentActor)
	spawn_cursor()


# spawns the buttons for selecting a unit for the current actor
func spawn_units() -> void:
	despawn_cursor()
	await battleOptions.spawn_units(currentActor, currentActor.selectedSkill.skillTarget)
	spawn_cursor()


func spawn_cursor() -> void:
	despawn_cursor()
	cursorPath = GameManager.spawn_cursor(
		battleOptions, battleOptions.items, 
		_on_optionChanged, _on_optionSelected, 
		Vector2(116, 8))


# displays dmg for a unit
func display_damage_nums(dmg : float, target : Unit, isCrit : bool = false, elemMod : float = 1, isHeal : bool = false) -> void:
	var number : DamageNumber = DMG_NUMS.instantiate()
	%damageNumbers.add_child(number)
	number.label.text = str(dmg) if dmg > 0 else "MISS"

	# set the position of the number
	var pos : Vector2 = GameManager.battleScene.get_screen_position(target.model)
	number.global_position = pos
	number.play_anim(isCrit, elemMod, isHeal)


func despawn_cursor() -> void: if cursorPath: GameManager.despawn_cursor(cursorPath)
func clear_actor_huds() -> void: for hud in actorHuds.get_children(): hud.queue_free()
func spawn_items() -> void: battleOptions.spawn_items()
