extends Control
class_name BattleMenu

const MENU_FX : String = "[center][bgcolor=000]"
const SKILL_BUTTON : PackedScene = preload("res://ui/ui_bat_skillButton.tscn")
const UNIT_BUTTON : PackedScene = preload("res://ui/ui_bat_unitButton.tscn")

@onready var menuTitle : RichTextLabel = %menuLabel
@onready var items : VBoxContainer = %options
@onready var scrollBox : ScrollContainer = %scroll
@onready var ATB : ProgressBar = %ATB

var forwardScrollIDX = 4
var backScrollIDX = -1
var menuIDX : int = 0
var HUD : BattleHUD

func _process(_delta) -> void:
	# controls the ATB gauge display
	if HUD && HUD.currentActor:
		var ratio : float = HUD.currentActor.battleTimer.time_left / HUD.currentActor.battleTimer.wait_time
		match HUD.currentActor.phase:
			Unit.Phase.WAITING:
				ATB.self_modulate = Color.DARK_RED
				ATB.indeterminate = false
				ATB.value = 1 - ratio
			Unit.Phase.CASTING:
				ATB.self_modulate = Color.CADET_BLUE
				ATB.indeterminate = false
				ATB.value = 1 - ratio
			Unit.Phase.QUEUED:
				ATB.self_modulate = Color.CADET_BLUE
				ATB.indeterminate = true
			Unit.Phase.SELECTING:
				ATB.self_modulate = Color.WHITE
				ATB.indeterminate = true
			Unit.Phase.DEAD:
				ATB.self_modulate = Color.DARK_ORCHID
				ATB.indeterminate = false
				ATB.value = 1 - ratio
			


func clear() -> void: for n in items.get_children(): n.queue_free()
func spawn_skills(actor : Actor) -> void:
	set_menu_text("SKILLS")
    # remove any skills previously there
	clear()

	# spawn the skill buttons
	for s : Skill in actor.skillList:
		var b : SkillButton = SKILL_BUTTON.instantiate()
		b.setup(s)
		items.add_child(b)
		await button_tween(b)
	await get_tree().create_timer(0.05).timeout


# spawns the correct units depending on the skill's target
func spawn_units(actor : Actor, skillTarget : Skill.TARGET_TYPES) -> void:
	set_menu_text("TARGET")
	clear()
	actor.target.clear()

	# spawns a button that targets all enemies
	var allEnem : Callable= func(text : String) -> void:
		var b : UnitButton = UNIT_BUTTON.instantiate()
		b.setup(GameManager.battleScene.formation.get_enemies(), text)
		items.add_child(b)
		await button_tween(b)

	# spawn the correct buttons depending on the skill target
	match skillTarget:
		# enemy select
		Skill.TARGET_TYPES.one_foe:
			for e : Enemy in GameManager.battleScene.formation.get_enemies():
				var b : UnitButton = UNIT_BUTTON.instantiate()
				b.setup([e])
				items.add_child(b)
				await button_tween(b)
			await get_tree().create_timer(0.05).timeout
				
		Skill.TARGET_TYPES.all_foe: await allEnem.call("All Enemies")
		
		# random select
		Skill.TARGET_TYPES.rand_1: items.add_child(await allEnem.call("One Random Enemy"))
		Skill.TARGET_TYPES.rand_2: items.add_child(await allEnem.call("Two Random Enemies"))
		Skill.TARGET_TYPES.rand_3: items.add_child(await allEnem.call("Three Random Enemies"))

		# actor select
		Skill.TARGET_TYPES.one_ally:
			for a : Actor in GameManager.battleScene.formation.get_actors():
				var b : UnitButton = UNIT_BUTTON.instantiate()
				b.setup([a])
				items.add_child(b)
				await button_tween(b)
			await get_tree().create_timer(0.05).timeout

		Skill.TARGET_TYPES.all_ally:
			var b : UnitButton = UNIT_BUTTON.instantiate()
			b.setup(GameManager.battleScene.formation.get_actors(), "All Allies")
			items.add_child(b)
			await button_tween(b)

		Skill.TARGET_TYPES.t_self:
			var b : UnitButton = UNIT_BUTTON.instantiate()
			b.setup([actor], "Self")
			items.add_child(b)
			await button_tween(b)


func button_tween(b : Node) -> void:
	var TW : Tween = create_tween().set_trans(Tween.TRANS_BACK)
	TW.tween_property(b, "position:x", 0, 0.1).from(b.position.x - 20)
	await get_tree().create_timer(0.05).timeout


func scroll_control(IDX : int) -> void:
	var scroll := scrollBox.scroll_vertical
	var scrollAmount : int = 32
	var scrollTime : float = 0.1
	var TW = create_tween().set_trans(Tween.TRANS_CUBIC)

	if IDX == 0:
		backScrollIDX = -1
		forwardScrollIDX = 4
		TW.tween_property(scrollBox, "scroll_vertical", 0, scrollTime)
	elif IDX == forwardScrollIDX:
		backScrollIDX += 1
		forwardScrollIDX += 1
		TW.tween_property(scrollBox, "scroll_vertical", scroll + scrollAmount, scrollTime)
	elif IDX == backScrollIDX:
		forwardScrollIDX -= 1
		backScrollIDX -= 1
		TW.tween_property(scrollBox, "scroll_vertical", scroll - scrollAmount, scrollTime)
	else: TW.kill()


func set_menu_text(text : String) -> void: menuTitle.text = MENU_FX + text.to_upper()