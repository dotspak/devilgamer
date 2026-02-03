@icon("res://icons/battleData.png")
extends Node
class_name Gear

enum FireSlot{ PRIMARY, SECONDARY }

@export var action_a : PackedScene

@export_category("Info")
@export var gearName : String = ""
@export_multiline var description : String = ""
@export var sprite : Texture

@export_category("Visuals")
@export var model : Node3D
@export var hitbox : Area3D
@export var animator : AnimationPlayer

@export_category("Attacks")
@export var primaryFire : PlayerAttackData = PlayerAttackData.new()
@export var secondaryFire : PlayerAttackData = PlayerAttackData.new()

var cooldownTimer : Timer
var passives : Array[Passive]
var entity : Entity
var currentFire : PlayerAttackData

@export var stacks : int = 0 :
	set(val):
		stacks = val
		stacksChanged.emit(stacks)

signal stacksChanged(stacks : int)
signal castStarted(slot : FireSlot)
signal castFinished(slot : FireSlot)
signal attackFinished(slot : FireSlot)

func _ready():
	if find_entity(get_parent()):
		for n : Node in get_children():
			if n is Passive: 
				passives.append(n)
				n.setup(entity)

	setup_cooldown_timer()
	verify_hitbox()

	if model: model.hide()
	attackFinished.connect(func(_slot): currentFire = null)


func setup_cooldown_timer() -> void:
	if cooldownTimer: cooldownTimer.queue_free()
	cooldownTimer = Timer.new()
	cooldownTimer.one_shot = true
	add_child(cooldownTimer)


func scale_animators(attack : PlayerAttackData) -> void: if animator: animator.speed_scale = attack.attackSpeed


# ---------------------
# getters
# ---------------------
func get_cast_time(slot : FireSlot = FireSlot.PRIMARY) -> float: return secondaryFire.castTime if slot == FireSlot.SECONDARY else primaryFire.castTime
func get_cooldown(slot : FireSlot = FireSlot.PRIMARY) -> float: return secondaryFire.cooldown if slot == FireSlot.SECONDARY else primaryFire.cooldown
func get_attack_speed(slot : FireSlot = FireSlot.PRIMARY) -> float: return secondaryFire.attackSpeed if slot == FireSlot.SECONDARY else primaryFire.attackSpeed
func get_attack_type(slot : FireSlot = FireSlot.PRIMARY) -> PlayerAttackData.AttackType: return secondaryFire.attackType if slot == FireSlot.SECONDARY else primaryFire.attackType
func get_fire(slot : FireSlot = FireSlot.PRIMARY) -> PlayerAttackData: return secondaryFire if slot == FireSlot.SECONDARY else primaryFire

# ---------------------
# hitboxes
# ---------------------
func verify_hitbox() -> void:
	if !hitbox: return
	hitbox.collision_layer = 8
	hitbox.collision_mask = 32
	hitbox.body_entered.connect(_hitbox_collision)


func set_hitbox_enabled(enabled : bool = true) -> void:
	if !hitbox:
		print(gearName, " has no hitbox!")
		return

	hitbox.monitoring = enabled
	hitbox.monitorable = enabled

func enable_hitbox() -> void: set_hitbox_enabled(true)
func disable_hitbox() -> void: set_hitbox_enabled(false)

func _hitbox_collision(node : Node3D) -> void:
	if node is Enemy:
		node.take_damage(currentFire.skill.calc_damage(GameManager.player))

# ---------------------
# signal callers
# ---------------------
func notify_cast_started(slot : FireSlot) -> void: 
	castStarted.emit(slot)

func notify_attack_finished(slot : FireSlot) -> void: 
	attackFinished.emit(slot)
	cooldownTimer.paused = false
	cooldownTimer.start()
	disable_hitbox()

func notify_cast_finished(slot : FireSlot) -> void: 
	castFinished.emit(slot)
	if animator:
		animator.speed_scale = currentFire.attackSpeed
		animator.play(currentFire.animation)

# ---------------------
# Fire logic
# ---------------------
func use_gear(slot : FireSlot = FireSlot.PRIMARY) -> void:
	if cooldownTimer.time_left > 0: return
	
	print("attempting to use gear " + gearName)
	currentFire = get_fire(slot)
	cooldownTimer.start(200)
	
	# cast the attack
	notify_cast_started(slot)
	await get_tree().create_timer(currentFire.castTime).timeout
	
	# use the attack
	notify_cast_finished(slot)
	await get_tree().create_timer(currentFire.attackSpeed).timeout

	# start cooldown
	cooldownTimer.start(currentFire.cooldown)
	notify_attack_finished(slot)

# ---------------------
# OUTDATED
# ---------------------
func use() -> void:
	var scene : PackedScene = get_action_scene()
	var attackSpeed : float = (1.0 + 0.38)
	owner.model.attack(attackSpeed)
	
	# spawn the gear's attack
	var action : Action = scene.instantiate()
	add_sibling(action)
	action.global_transform = owner.castPosition.global_transform
	action.spawn(owner, owner.targetter.softTarget)

	# handle the cooldowns between each use of the gear
	if cooldownTimer: 
		cooldownTimer.queue_free()
		cooldownTimer = null
	cooldownTimer = Timer.new()
	cooldownTimer.timeout.connect(func():
		owner.cooldowns.erase(cooldownTimer)
		cooldownTimer.queue_free())
	add_child(cooldownTimer)
	owner.cooldowns.append(cooldownTimer)
	cooldownTimer.start(action.skill.cooldown)


func find_entity(parent : Node) -> bool:
	if parent is Entity: entity = parent
	elif parent == get_tree().root: return false
	else: find_entity(parent.get_parent())
	return true
	

func instance_action() -> Action:
	var inst : Node = action_a.instantiate()
	return inst if inst is Action else null


# getters --------------------------------
func get_action_scene() -> PackedScene: return action_a
func get_sprite() -> Texture: return sprite


func get_skill() -> Skill:
	var inst : Action = instance_action()
	return inst.skill if inst else null


func get_skill_desc() -> String:
	var inst : Action = instance_action()
	return inst.skill.description if inst else ""


func get_info() -> Dictionary:
	var info : Dictionary = {"NAME" : "", "DESCRIPTION" : ""}
	var action : Action = instance_action()
	if action:
		info.NAME = action.skill.name
		info.DESCRIPTION = action.skill.description
	return info


func is_on_cooldown() -> bool: return !cooldownTimer.is_stopped()
