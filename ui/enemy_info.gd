extends Panel
class_name EnemyInfo

const ROT : float = 45

# determines the mode the HUD is in
var row : int = 0
var mode : int = 0

# selection variables
var IDX : int :
	set(val):
		IDX = clamp(val, 0, GameManager.battleScene.grid.grid[row].size() - 1)
		if IDX >= 0:
			target = GameManager.battleScene.grid.grid[row][IDX]
		elif IDX == -2:
			target = actor
var actor : Unit # the actor who's turn it currently is
var target : Unit : # the target the hud is targetting
	set(val):
		if target: target.model.hide_outline()
		target = val

		# camera control
		if is_one_selection() && target is Enemy: GameManager.battleScene.focus_camera(target)
		else: GameManager.battleScene.center_camera()
		
		# change the properties according to the new target
		setup()

# emitting when the hud is closed, and singals whether it was a cancel or not
signal exit(confirmed : bool)

func _ready() -> void:
	set_process_input(false)
	$name.text = ""
	$icon.texture.region.position.x = 0

	await enter_anim()

# starts the logic based on the passed parameters
func start(targetRow : int = 1, selectionMode : Skill.TARGET_TYPES = Skill.TARGET_TYPES.one_foe) -> void:
	mode = selectionMode
	row = targetRow
	if is_one_selection(): IDX = 0
	else: IDX = -1

# handles input navigation
func _process(_delta : float):
	# handles swapping enemies
	if is_one_selection():
		if Input.is_action_just_pressed("ui_left"): IDX -= 1
		elif Input.is_action_just_pressed("ui_right"): IDX += 1

	# handles cancel/confirm
	if Input.is_action_just_pressed("ui_cancel"):
		await exit_anim()
		exit.emit(false)
		queue_free()
	elif actor && Input.is_action_just_pressed("ui_accept"): # only allow if selecting enem
		# treat the accept as a skill target
		if actor.selectedSkill:
			if actor.selectedSkill.skillTarget == Skill.TARGET_TYPES.one_foe || actor.selectedSkill.skillTarget == Skill.TARGET_TYPES.one_ally:
				actor.target.append(target)
			elif actor.selectedSkill.skillTarget == Skill.TARGET_TYPES.all_foe || actor.selectedSkill.skillTarget == Skill.TARGET_TYPES.all_ally:
				for u : Unit in GameManager.battleScene.grid.grid[row]:
					actor.target.append(u)
			elif actor.selectedSkill.skillTarget == Skill.TARGET_TYPES.rand_1:
				actor.target.append(GameManager.battleScene.grid.grid[row].pick_random())
			elif actor.selectedSkill.skillTarget == Skill.TARGET_TYPES.rand_2:
				actor.target.append(GameManager.battleScene.grid.grid[row].pick_random())
				actor.target.append(GameManager.battleScene.grid.grid[row].pick_random())
			elif actor.selectedSkill.skillTarget == Skill.TARGET_TYPES.rand_3:
				actor.target.append(GameManager.battleScene.grid.grid[row].pick_random())
				actor.target.append(GameManager.battleScene.grid.grid[row].pick_random())
				actor.target.append(GameManager.battleScene.grid.grid[row].pick_random())
			else:
				actor.target.append(target)
		else:
			exit.emit(false)
		await exit_anim()
		exit.emit(true)

# displays the information of the current target
func setup() -> void:
	var dispText : String = "Oh no, you broke the text display!"
	var elem : int = -1
	set_process_input(false)

	# handles if you are selecting one target
	if is_one_selection() || mode == Skill.TARGET_TYPES.t_self: 
		dispText = target.charSheet.name
		elem = target.element

		# change the outline to match the situation
		target.model.show_outline(BattlePuppet.DEF_OUTLINE)
		if actor.selectedSkill:
			# handles if the target is weak to the hit
			if Element.reaction_ref(actor.selectedSkill.element, target.element) >= 2:
				target.model.show_outline(BattlePuppet.WEAK_OUTLINE)

			# handles if the skill is resisted by the target
			elif target.is_resisted(actor.selectedSkill.element) <= 0.5:
				target.model.show_outline(BattlePuppet.RES_OUTLINE)
	
	# handles if multiple targets are being selected
	else:
		for u : Unit in GameManager.battleScene.grid.grid[row]:
			u.model.show_outline(BattlePuppet.DEF_OUTLINE)
			if actor.selectedSkill:
				# handles if the target is weak to the hit
				if Element.reaction_ref(actor.selectedSkill.element, target.element) >= 2:
					u.model.show_outline(BattlePuppet.WEAK_OUTLINE)

				# handles if the skill is resisted by the target
				elif target.is_resisted(actor.selectedSkill.element) <= 0.5:
					u.model.show_outline(BattlePuppet.RES_OUTLINE)
		match mode:
			Skill.TARGET_TYPES.all_foe:
				dispText = "All Foes"
			Skill.TARGET_TYPES.all_ally:
				dispText = "All Allies"
			Skill.TARGET_TYPES.rand_1:
				dispText = "One Random Foe"
			Skill.TARGET_TYPES.rand_2:
				dispText = "Two Random Foes"
			Skill.TARGET_TYPES.rand_3:
				dispText = "Three Random Foes"

	# display the text and element
	await GameManager.battleScene.show_top_text(dispText, elem)
	
	set_process_input(true)

func enter_anim() -> void:
	var TW = create_tween().set_parallel()
	TW.tween_property(self, "scale", Vector2.ONE, 0.2).from(Vector2.ZERO)
	TW.tween_property(self, "rotation", 0, 0.2).from(deg_to_rad(ROT))
	await TW.finished

func exit_anim() -> void:
	var TW = create_tween().set_parallel()
	TW.tween_property(self, "scale", Vector2.ZERO, 0.2)
	TW.tween_property(self, "rotation", deg_to_rad(ROT), 0.2)
	for u : Unit in GameManager.battleScene.grid.grid[row]:
		u.model.hide_outline()
	await TW.finished
	queue_free()

func is_one_selection() -> bool: return mode == Skill.TARGET_TYPES.one_ally || mode == Skill.TARGET_TYPES.one_foe
