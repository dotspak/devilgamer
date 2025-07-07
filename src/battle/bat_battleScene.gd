# bat_battleScene.gd ---------------------------------
# Handles all logic related to running the battle,
# playing skill animations, turn order, etc.
# only one instance of this scene is used for battles, and is
# adapted based on the passed info
@icon("res://icons/battle.png")
extends Node3D
class_name BattleScene3D

const BATTLE_HUD : PackedScene = preload("res://ui/ui_bat_battleHUD.tscn")

@export var troop : Troop
@export var temp_actorSheets : Array[ActorSheet]

@onready var formation : BattleFormation = %formation
@onready var camera : Camera3D = %defaultCam

var HUD : BattleHUD
var environment : BattleEnvironment
var actionQueue : Array[Dictionary]

func _ready():
	GameManager.battleScene = self
	spawn_environment()
	
	# spawn in the units for battle
	for a : ActorSheet in temp_actorSheets: formation.add_actor(spawn_actor(a))
	for e : EnemySheet in troop.enemies: formation.add_enemy(spawn_enemy(e))

	spawn_battle_hud()

	var units : Array[Unit] = formation.get_units()
	position_units(units)
	initiate_battle(units)
	battle_loop()


# spawns the environment associated with the passed troop
func spawn_environment() -> void:
	environment = troop.environment.instantiate()
	if environment.camera: camera = environment.camera
	add_child(environment)


# spawns an actor
func spawn_actor(sheet : ActorSheet) -> Actor:
	var actor : Actor = Actor.new(sheet)
	actor.model = sheet.model.instantiate()
	actor.add_child(actor.model)
	#actor.battleTimer.paused = true
	%actorNodes.add_child(actor)
	return actor


# spawns an enemy
func spawn_enemy(sheet : EnemySheet) -> Enemy:
	var enemy : Enemy = Enemy.new(sheet)
	enemy.model = sheet.model.instantiate()
	enemy.add_child(enemy.model)

	enemy.battleScript = sheet.battleScript.new()
	enemy.add_child(enemy.battleScript)

	%enemyNodes.add_child(enemy)
	return enemy


# positions units according to how many currently exist
func position_units(units : Array[Unit]) -> void:
	for i : int in units.size():
		var u : Unit = units[i]
		var amount : int = formation.get_actors().size() if u is Actor else formation.get_enemies().size()

		match amount:
			3: u.position.x = -3 + ((i % 3) * 3)
			2: u.position.x = -2 + ((i % 3) * 4)
			1: u.position.x = 0
		
		if u is Actor: u.position.x *= -1


# creates the battle HUD in game, and sets up the references to it (canvas layer is temporary)
func spawn_battle_hud() -> void:
	var cl : CanvasLayer = CanvasLayer.new()
	HUD = BATTLE_HUD.instantiate()
	add_child(cl)
	cl.add_child(HUD)
	HUD.setup(formation.get_actors())


# sets up the remaining aspects needed for battle
func initiate_battle(units : Array[Unit]) -> void: 
	for u : Unit in units:
		u.timerElapsed.connect(_on_unit_timeout)
		u.finishedDying.connect(handle_unit_death.bind(u))
		u.start_battle()
		

# handles what logic to trigger based on the unit's phase when the timer times out
func _on_unit_timeout(unit : Unit) -> void:
	match unit.phase:
		# unit's waiting phase is complete, move to selection
		Unit.Phase.WAITING: 
			unit.enter_selecting_phase()
		
		# unit has finished casting, add their skill to queue
		Unit.Phase.CASTING:
			add_action(unit)
			unit.enter_queued_phase()

		# unit has perished, mostly for revive logic for actors
		Unit.Phase.DEAD:
			if unit is Actor: pass
		
		# default to waiting phase in case of error
		_: unit.enter_waiting_phase()


# controls the flow of the battle. Mainly just trigers actions when they are
# ready to be triggered, but also checks if the battle should end or not
func battle_loop() -> void:
	# loops until an end battle condition is met
	var battleCheck : int = should_battle_end()
	while battleCheck < 0:
		await get_tree().create_timer(0.5).timeout
		if !actionQueue.is_empty(): await handle_action(actionQueue.pop_front())
		battleCheck = should_battle_end()

	# clear the queue to ensure no accidental actions happen
	actionQueue.clear()
	
	# checks if the battle was a victory or not
	if battleCheck == 0:
		print("YOU LOST")
		get_tree().quit()
	else:
		print("YOU WIN")
		get_tree().quit()


# creates an action and adds it to the queue
func add_action(unit : Unit, flags : Array = []) -> Dictionary: 
	var action : Dictionary = {
		"unit" : unit,
		"action" : unit.selectedSkill,
		"flags" : flags
	}
	actionQueue.append(action)
	return action


# handles the passed action
func handle_action(action : Dictionary) -> void:
	if actionQueue.has(action): actionQueue.erase(action)
	if !check_valid_action(action): return
	retarget_action(action)
	action.unit.start_turn()
	await action.unit.turnEnded


# checks if the current action is valid
func check_valid_action(action : Dictionary) -> bool:
	var valid : bool = true
	if !formation.get_units().has(action.unit): valid = false
	if action.unit.phase == Unit.Phase.DEAD: valid = false
	return valid


# retargets action if any targets are dead depending on the action
func retarget_action(action : Dictionary) -> void:
	var skill : Skill = action.unit.selectedSkill
	var isActor : bool = action.unit is Actor

	# loop through all the targets of the skill and check if they are dead
	for i : int in action.unit.target.size():
		var u : Unit = action.unit.target[i]
		if u.phase == Unit.Phase.DEAD:
			if skill.all_target(): 
				action.unit.target.erase(u)
			else:
				var actorSide : bool = (skill.ally_target() && isActor) || (!skill.ally_target() && !isActor)
				action.unit.target[i] = formation.get_actors().pick_random() if actorSide else formation.get_enemies().pick_random()


# handles when a unit has finished dying
func handle_unit_death(unit : Unit) -> void:
	if unit is Enemy: unit.position.y = -INF


# -1 : battle should continue, 0 : battle ends, loss, 1: battle ends, win
func should_battle_end() -> int:
	if formation.are_actors_dead(): return 0
	elif formation.are_enemies_dead(): return 1
	else: return -1
 

# used for spawning an enemy after battle has started, for summon skills
func post_enemy_spawn(sheet : EnemySheet) -> void:
	formation.add_enemy(spawn_enemy(sheet))
	position_units(formation.get_units())

func pause_timers() -> void: for u : Unit in formation.get_units(): u.battleTimer.paused = true
func unpause_timers() -> void: for u : Unit in formation.get_units(): u.battleTimer.paused = false
func spawn_skillAnim(anim : SkillAnim) -> void: add_child(anim)
func get_screen_position(node : Node3D) -> Vector2: return camera.unproject_position(node.global_position)
