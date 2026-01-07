@icon("res://icons/gearIcon.png")
extends Node
class_name Gear

@export var gearName : String = ""
@export_multiline var description : String = ""
@export var sprite : Texture

@export_group("Primary Fire")
@export var skill_a : Skill
@export var action_a : PackedScene

@export_group("Secondary Fire")
@export var skill_b : Skill
@export var action_b : PackedScene

var cooldownTimer : Timer
var statComponent : StatComponent
var passives : Array[Passive]
var entity : Entity

@export var stacks : int = 0 :
	set(val):
		stacks = val
		stacksChanged.emit(stacks)

signal stacksChanged(stacks : int)

func _ready():
	if find_entity(get_parent()):
		for n : Node in get_children():
			if n is Passive: 
				passives.append(n)
				n.setup(entity)
				
			if n is StatComponent: 
				statComponent = n


func use() -> void:
	var scene : PackedScene = get_action_scene()
	var attackSpeed : float = (1.0 + 0.38) / skill_a.cooldown
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
