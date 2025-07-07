# battleScene.gd ---------------------------------
# Handles all logic related to running the battle,
# playing skill animations, turn order, etc.
# only one instance of this scene is used for battles, and is
# adapted based on the passed info
extends Node2D
class_name BattleScene

# default positions
const TOP_TEXT_HIDE : int = -12
const TOP_TEXT_SHOW : int = 8
const BOT_TEXT_HIDE : int = 188
const BOT_TEXT_SHOW : int = 144
const ENEM_INFO_POS : Vector2 = Vector2(0,0)
const DMG_NUM_ENEMY_Y : int = 152
const DMG_NUM_ACTOR_Y : int = 216
const BLOOD_Y_ENEM : int = 96

# scenes to be instantiated
const DMG_NUMS : PackedScene = preload("res://ui/damageNumbers.tscn")
const HEAL : PackedScene = preload("res://assets/particles/heal_splatter.tscn")
const BLOOD : PackedScene = preload("res://assets/particles/blood_splatter.tscn")
const ACTOR_HUD : PackedScene = preload("res://ui/actorHud.tscn")
const ENEM_INFO : PackedScene = preload("res://ui/enemyInfo.tscn")

@export_group("setup")
@export var troop : Troop

@export_group("units")
@export var actors : Array[ActorSheet]
@export var enemies : Array[EnemySheet]

@onready var grid : BattleGrid = $grid
@onready var skillArea : Node2D = $grid/skills
@onready var actorSkills : Node2D = $CanvasLayer/actorSkills
@onready var camera : Camera2D = $Camera2D
@onready var actorHuds = %actorHuds

# UI onreadys 
@onready var topText : Label = $CanvasLayer/UI/topText
@onready var bottomText : Label = $CanvasLayer/UI/bottomText
@onready var actionSelect : BattleOptions = %actionSelect

# enemy positions
@onready var enem_pos : Array[Vector2] = [
	$EnemPositions/left.position, # left
	$EnemPositions/center.position, # center
	$EnemPositions/right.position # right
]

# in battle info
var readyQueue : Array[Unit]
var dyingUnits : Array[Unit]
var hudRef : Dictionary

# initialization -----------------------------------------------------------------
func _ready() -> void:
	# set the battle scene
	#GameManager.battleScene = self

	# hide boxes
	%screen.show()
	hide_action_select()
	hide_top_text()
	hide_bottom_text()

	# place the units on the board
	var actorList : Array[Unit] = []
	var enemyList : Array[Unit] = []
	for a : ActorSheet in actors: actorList.append(spawn_actor(a))
	for e : EnemySheet in enemies: enemyList.append(spawn_enemy(e))

	# set up the grid
	grid.setup([actorList, enemyList])
	center_camera()
	camera.reset_smoothing()

	# intro animation
	await intro_animation()
	for a : Unit in actorList: spawn_actor_hud(a)
	
	await get_tree().create_timer(0.3).timeout

	# initiate the battle loop
	print("STARTING BATTLE")
	battle_loop()

# spawns the actor's hud
func spawn_actor_hud(actor : Unit) -> void:
	var hud : ActorHud = ACTOR_HUD.instantiate()
	actorHuds.add_child(hud)
	hud.setup(actor)
	hudRef[actor] = hud
	await actor_hud_enter_anim(hud)

# plays the animation when battles start
func intro_animation() -> void:
	var viewStylebox : StyleBoxFlat = %UI/enemyView.get("theme_override_styles/panel")

	var borderTW = create_tween()
	for _i : int in range(3):
		borderTW.tween_property(viewStylebox, "border_color", Color(0.5, 0, 0), 0.1)
		borderTW.tween_property(viewStylebox, "border_color", Color.BLACK, 0.1)
	borderTW.tween_property(viewStylebox, "border_color", Color(0.5, 0, 0), 0.1)
	
	await borderTW.finished

	var screenTW = create_tween()
	screenTW.tween_property(%screen, "color", Color(Color.BLACK, 0), 0.4).from(Color.BLACK)

# animation for when an actor hud is added
func actor_hud_enter_anim(hud : ActorHud) -> void:
	var TW = create_tween().set_trans(Tween.TRANS_BACK)
	TW.tween_property(hud, "position:y", 0, 0.2).from(40)
	await TW.finished

# places an actor on the board
func spawn_actor(sheet : CharSheet) -> Unit:
	var actor : Actor = Actor.new(sheet)
	var sprite = sheet.sprite.instantiate()
	actor.model = sprite
	%actors.add_child(actor)
	unit_setup(actor)
	return actor

# places an enemy on the board
func spawn_enemy(sheet : EnemySheet) -> Unit:
	var enemy : Enemy = Enemy.new(sheet)
	var sprite = sheet.sprite.instantiate()
	enemy.battleScript = sheet.battleScript.new()
	enemy.add_child(sprite)
	enemy.add_child(enemy.battleScript)
	enemy.model = sprite
	%enemies.add_child(enemy)

	# position the enemy properly
	# if enemies.size() == 1: enemy.position = enem_pos[1]
	# else: enemy.position = enem_pos[enemies.find(sheet)]
	
	unit_setup(enemy)
	return enemy

# setups info about the unit, like signal connections
func unit_setup(unit : Unit) -> void:
	unit.finishedDying.connect(handle_unit_death.bind(unit))

# turn logic -------------------------------------------------------
# starts the battle loop that handles turn order, and choosing actions
func battle_loop() -> void:
	var unitToAct : Unit = null
	center_camera()

	# keep looping until a unit is decided to act
	while !unitToAct: unitToAct = get_next_turn()

	# once a unit is decided, take their turn
	await take_turn(unitToAct)

	# wait for death animations, if anything died
	await check_unit_death()
	
	# check the status of the battle at the end of the turn
	if should_battle_end(): end_battle(grid.check_units_alive(0))
	else: battle_loop() # restart the loop

# determines which units should act next
func get_next_turn() -> Unit:
	# if there are units ready to take their turn, pop the first unit
	if !readyQueue.is_empty(): return readyQueue.pop_front()
	
	# otherwise begin the process of determining the next unit
	var string : String = ""
	for u : Unit in grid.get_units() + grid.deadActors:
		if !u: continue
		string += u.charSheet.name + " " + str(u.decrement_cooldown()) + "    "
		if u.turnPoints <= 0:
			readyQueue.append(u)
	print(string)

	return null

# starts the passed unit's turn
func take_turn(unit : Unit) -> void:
	print(unit.charSheet.name, " is taking their turn!")
	await get_tree().create_timer(0.5).timeout
	
	# handles the turn depending on the type of unit
	if unit is Actor: await actor_turn(unit)
	else: actionSelect.hide_options()

	# for actors, uses whatever action is selected, enemies choose their actcion
	unit.start_turn()
	await unit.turnEnded
	if unit is Actor:
		hudRef[unit].turnBar.max_value = unit.turnPoints

# handles the actor's turn
func actor_turn(actor : Actor) -> void:
	# handle decrementing the downcount if the actor is dead
	if actor.downCount > 0: 
		print(actor.charSheet.name, " is down!")
		return
	
	# highlight the hud of the actor taking their turn
	hudRef[actor].anim.play("selected")

	# loop until the actor has chosen an action
	while !actor.selectedSkill:
		# handles choosing a skill
		await show_action_select(actor)
		await actionSelect.finished
		hide_action_select()

		# handles targetting an enemy
		await display_enem_info(actor)

		# reset if no target was selected (ie cancelled)
		if actor.target.is_empty(): actor.selectedSkill = null
	hide_bottom_text()
	await hide_top_text()
	hudRef[actor].anim.stop()

# displays the enemy info screen, if its being used for skill selection,
func display_enem_info(actor : Unit) -> bool:
	# set up the info box
	var infoBox : EnemyInfo = ENEM_INFO.instantiate()
	infoBox.actor = actor
	infoBox.position += ENEM_INFO_POS

	# determines if targetting allies or enemies
	var row : int = 0 if (
		actor.selectedSkill.skillTarget == Skill.TARGET_TYPES.all_ally || 
		actor.selectedSkill.skillTarget == Skill.TARGET_TYPES.one_ally) else 1

	# spawn the info box, wait for it to be completed
	%UI.add_child(infoBox)
	infoBox.start(row, actor.selectedSkill.skillTarget)
	return await infoBox.exit
   
# checks all of the units 
func check_unit_death() -> void:
	# store any dying units
	for u : Unit in grid.get_units():
		if u is Actor && u.downCount > 0: continue
		if u.HP <= 0:
			u.trigger_death()
			dyingUnits.append(u)
	
	# wait until all units have finished their death animation
	while !dyingUnits.is_empty(): await get_tree().create_timer(0.01).timeout

# handles when the unit actually dies, after all animations
func handle_unit_death(unit : Unit) -> void:
	dyingUnits.erase(unit)

	# delete the unit from the queue if they are in it
	var wasReady : int = readyQueue.find(unit)
	if wasReady >= 0: readyQueue.erase(unit)
	
	# logic for actor death
	if unit is Actor:
		grid.deadActors.resize(3)
		grid.deadActors[grid.grid[0].find(unit)] = unit

	# delete the unit from the grid
	grid.remove_unit(unit)

	unit.model.visible = false
	unit.visible = false

# puts the actor back in the correct spot in the grid
func handle_actor_revive(actor : Actor) -> void:
	grid.grid[0].resize(3)
	grid.grid[0].insert(grid.deadActors.find(actor), actor)
	grid.deadActors.erase(actor)
	
# checks whether battle should end of not
func should_battle_end() -> bool: return !grid.check_units_alive(0) || !grid.check_units_alive(1)

# ends the battle
func end_battle(victory : bool = true) -> void:
	# handle the victory screen
	if victory: print("YOU WON!")
	else: print("YOU LOST!")

	# end the battle scene
	GameManager.battleScene = null
	await get_tree().create_timer(0.5).timeout
	get_tree().quit()

# camera controls --------------------------------------------
func center_camera() -> void: camera.position.x = grid.get_enemy_center()
func focus_camera(target : Unit) -> void: camera.position.x = target.position.x

# visual information/animations ----------------------------------------
# shows the player's options for battle
func show_action_select(actor : Unit) -> void:
	# display the text fields
	show_top_text(actor.charSheet.name)

	# display the options
	actionSelect.show_options()
	await actionSelect.spawn_skills(actor)

# hides the player's options for battle
func hide_action_select() -> void:
	await actionSelect.hide_options()

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
	if text != "": topText.text = text
	
	var TW = create_tween().set_trans(Tween.TRANS_BACK)
	TW.tween_property(topText, "position:y", TOP_TEXT_SHOW, 0.2)
	await TW.finished

# manually hides top text
func hide_top_text() -> void:
	var TW = create_tween()
	TW.tween_property(topText, "position:y", TOP_TEXT_HIDE, 0.1)
	await TW.finished

# shows bottom text as an animation
func display_bottom_text(text : String = "", duration : float = 1.0) -> void:
	await show_bottom_text(text)
	await get_tree().create_timer(duration).timeout
	await hide_bottom_text()

# shows bottom text and keeps it there
func show_bottom_text(text : String = "") -> void:
	if text != "": bottomText.text = text

	var TW = create_tween().set_trans(Tween.TRANS_BACK).set_parallel(true)
	TW.tween_property(bottomText, "position:y", BOT_TEXT_SHOW, 0.3)
	TW.tween_property(bottomText, "visible_ratio", 1, bottomText.text.length() * 0.03).from(0).set_trans(Tween.TRANS_LINEAR)
	await TW.finished

# manually hides bottom text
func hide_bottom_text() -> void:
	var TW = create_tween()
	TW.tween_property(bottomText, "position:y", BOT_TEXT_HIDE, 0.1)
	await TW.finished

# displays dmg for a unit
func display_damage_nums(dmg : float, target : Unit, isCrit : bool = false, elemMod : float = 1, isHeal : bool = false) -> void:
	var number : DamageNumber = DMG_NUMS.instantiate()
	$CanvasLayer/DamageNums.add_child(number)
	number.label.text = str(dmg) if dmg > 0 else "MISS"

	# set the position of the numbers
	var t : Transform2D = target.model.get_global_transform_with_canvas()
	number.position = t.get_origin()
	if target is Actor: number.position.y = DMG_NUM_ACTOR_Y
	else: number.position.y = DMG_NUM_ENEMY_Y
	
	number.play_anim(isCrit, elemMod, isHeal)

# blood splatter code
func display_blood_splatter(amount : float, target : Unit) -> void:
	# get the particle instance
	var particles : GPUParticles2D = BLOOD.instantiate()
	particles.amount = ceili(amount)
	
	# position the particles correctly
	target.model.add_child(particles)
	if target is Enemy: particles.global_position.y = BLOOD_Y_ENEM
	else:
		particles.global_position.y = DMG_NUM_ACTOR_Y
		particles.process_material.emission_box_extents = Vector3.ONE * 10

	# emit the particles
	particles.finished.connect(particles.queue_free)
	particles.emitting = true

func display_heal_splatter(target : Unit) -> void:
	var particles : GPUParticles2D = HEAL.instantiate()

	# position the particles correctly
	target.model.add_child(particles)
	if target is Enemy: particles.global_position.y = BLOOD_Y_ENEM
	else:
		particles.global_position.y = DMG_NUM_ACTOR_Y
		particles.process_material.emission_box_extents = Vector3.ONE * 10

	# emit the particles
	particles.finished.connect(particles.queue_free)
	particles.emitting = true

	display_blood_splatter(1, target)
