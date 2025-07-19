# entity.gd --------------------------------
# master class for any character that can interact with combat.
# only logic related to taking damage is in this class, other things such
# as and skills should be handled separately.
extends CharacterBody3D
class_name Entity

const DMG_NUM : PackedScene = preload("res://ui/ui_dmgpopup.tscn")

@export var skillTarget : Entity: set = set_target
@export var castPosition : Marker3D
@export var mesh : MeshInstance3D
@export var targetPosition : Marker3D
@export var targetArea : Area3D
@export var model : Node3D

@export_group("Components")
@export var stats : StatComponent

var cooldowns : Array[Timer] = []
var usingSkill : bool = false
var movementAllowed : bool = true
var stopMoveWeight : float = 0.3

var dead : bool = false

signal entityDeath

func _ready():
	if stats: stats.hpChanged.connect(should_entity_die)


func display_damage_num(dmg : float, isHeal : bool = false, isCrit : bool = false, isWeak : bool = false, isRes : bool = false) -> void:
	var num : Sprite3D = DMG_NUM.instantiate()
	num.popupDone.connect(num.queue_free)
	add_child(num)
	num.position = Vector3(randf_range(-1,1), randf_range(-1,1), randf_range(-1,1))
	num.display_dmg(dmg, isHeal, isCrit, isWeak, isRes)


# checks if the player can cast the passed skill 
# (for now is just a basic check)
func should_use_skill(_skill = null) -> bool:
	if !usingSkill:
		return cooldowns.is_empty() && skillTarget
	return false


# this code will later be used to use any action from a skill, for testing
# it only currently uses the basic fireball.
func use_action(scene : PackedScene) -> void:
	stop_movement(0.6)
	usingSkill = true

	var action : Action = scene.instantiate()
	action.spawn(skillTarget, self)
	add_sibling(action)
	action.global_position = castPosition.global_position
	action.actionFinished.connect(func(): 
		movementAllowed = true
		usingSkill = false
	)

	var cooldownTimer : Timer = Timer.new()
	add_child(cooldownTimer)
	cooldowns.append(cooldownTimer)
	cooldownTimer.start(0.1)
	cooldownTimer.timeout.connect(cooldowns.erase.bind(cooldownTimer))


func stop_movement(weight : float = 0.3) -> void:
	if !movementAllowed: return
	movementAllowed = false
	stopMoveWeight = weight


# mostly used so the player can apply targetting effects
func set_target(t : Entity) -> void: skillTarget = t

func get_target_size() -> float:
	if mesh:
		var aabb : AABB = mesh.get_aabb()
		var avgSize : float = (aabb.size.x + aabb.size.z) / 2.0
		return avgSize * 80
	return 1.0


func get_closest_target() -> Node3D:
	var bodies : Array[Node3D] = targetArea.get_overlapping_bodies()
	bodies.erase(self)
	if bodies.is_empty(): return null

	var forward : Vector3 = -global_basis.z
	var origin : Vector3 = global_transform.origin
	var maxAngleDeg : float = 60
	var minDot = cos(deg_to_rad(maxAngleDeg))

	var closest : Node3D = bodies[0]
	var minDist : float = global_position.distance_to(closest.global_position)

	for body in bodies: 
		if !body is CharacterBody3D: continue

		var toTarget : Vector3 = (body.global_transform.origin - origin).normalized()
		var dot : float = forward.dot(toTarget)

		if dot >= minDot:
			var dist : float = global_position.distance_to(body.global_position)
			if dist < minDist:
				minDist = dist
				closest = body

	return closest


# deals damage to the entity.
func take_damage(baseDMG : float, casterStats : StatComponent, dmgType : Skill.DMG_TYPES = Skill.DMG_TYPES.PHYS) -> void:
	var dmgReduction : float = 0.0
	match dmgType:
		Skill.DMG_TYPES.PHYS: dmgReduction = stats.get_stat(StatComponent.STATS.DEF)
		Skill.DMG_TYPES.MAG: dmgReduction = stats.get_stat(StatComponent.STATS.MDF)
		Skill.DMG_TYPES.TRUE: dmgReduction = 0
	
	var crit : bool = randf_range(0, 1) <= casterStats.calc_crit_chance()
	if crit: baseDMG *= casterStats.get_rate(StatComponent.RATES.CRITDMG)
	
	var finalDMG = max(baseDMG * (
		GameConstants.DEF_SCALE / 
		(GameConstants.DEF_SCALE + dmgReduction)), 0)
	finalDMG = roundf(finalDMG)
	
	if model.has_method("damage_flash"):
		model.damage_flash()
	display_damage_num(finalDMG, false, crit, false, false)
	stats.HP -= finalDMG

	print(name + " took " + str(int(finalDMG)) + " DMG!")


func heal_damage(baseHeal : float) -> void:
	display_damage_num(baseHeal, true)
	stats.HP += baseHeal


func should_entity_die(hp : float) -> bool:
	if hp <= 0:
		kill()
		return true
	return false


func kill() -> void:
	print(name + " died")
	entityDeath.emit()
	set_process(false)
	set_physics_process(false)
	dead = true
	queue_free()
