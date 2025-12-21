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
@export var modelController : EntityModelController
@export var bloodScene : PackedScene = preload("res://assets/particles/pe_hitBlood.tscn")

@export_group("Components")
@export var stats : StatComponent
@onready var stateMachine : StateMachine = $StateMachine

var cooldowns : Array[Timer] = []
var usingSkill : bool = false
var movementAllowed : bool = true
var stopMoveWeight : float = 0.1
var selectedAction : PackedScene = load("res://scenes/actions/tripleShot.tscn")
var isDead : bool = false

var healthComponent : HealthComponent

signal entityDeath
signal tookDamage

func _ready() -> void:
	store_health_component()
	if modelController: entityDeath.connect(modelController.create_death_effect)
	if healthComponent: healthComponent.hpChanged.connect(should_entity_die)

func store_health_component() -> void:
	healthComponent = Utils.get_component(self, HealthComponent)

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
		return cooldowns.is_empty()
	return false


# this code will later be used to use any action from a skill, for testing
# it only currently uses the basic fireball.
func use_action(scene : PackedScene) -> void:
	usingSkill = true

	var action : Action = scene.instantiate()
	add_sibling(action)
	action.global_transform = castPosition.global_transform
	action.spawn(self, skillTarget)

	var skillLockTimer : Timer = Timer.new()
	skillLockTimer.timeout.connect(func():
		usingSkill = false
		skillLockTimer.queue_free())
	add_child(skillLockTimer)
	skillLockTimer.start(action.skill.skillLock)

	var cooldownTimer : Timer = Timer.new()
	cooldownTimer.timeout.connect(func():
		cooldowns.erase(cooldownTimer)
		cooldownTimer.queue_free())
	add_child(cooldownTimer)
	cooldowns.append(cooldownTimer)
	cooldownTimer.start(action.skill.cooldown)


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
func take_damage(amount : float, crit : bool = false, isTrueDmg : bool = false) -> void:
	if !healthComponent: return
	if isDead: return

	amount = healthComponent.take_damage(amount, isTrueDmg)
	
	if modelController: modelController.damage_flash()
	display_damage_num(amount, false, crit, false, false)

	var bloodAmount : float = clampf((amount / healthComponent.maxHealth) * 1.3, 0.1, 1.0)
	blood_splatter(bloodAmount)
	flash_model(Color(2, 0, 0))

	tookDamage.emit()
	print(name + " took " + str(int(amount)) + " DMG!")


func blood_splatter(amount : float) -> void:
	var blood : BloodSplatter = bloodScene.instantiate()
	add_sibling(blood)
	blood.global_transform = global_transform
	blood.spawn(amount)


func flash_model(color : Color = Color(2, 0, 0)) -> void:
	if !model: return

	var flashMat : StandardMaterial3D = StandardMaterial3D.new()
	flashMat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	flashMat.albedo_color = color
	flashMat.albedo_color.a = 0

	var meshes : Array[MeshInstance3D]
	for n : Node in model.get_children(true):
		if n is MeshInstance3D:
			meshes.append(n)
			n.material_overlay = flashMat

	var TW : Tween = create_tween()
	TW.tween_property(flashMat, "albedo_color:a", 1, 0.05).from(0)
	TW.tween_property(flashMat, "albedo_color:a", 0, 0.05).from(1)


func heal_damage(baseHeal : float) -> void:
	if !healthComponent: return

	baseHeal = healthComponent.heal_damage(baseHeal)
	display_damage_num(baseHeal, true)
	flash_model(Color(0, 2, 0.2))


func should_entity_die(hp : float) -> bool:
	if hp <= 0:
		kill()
		return true
	return false


func kill() -> void:
	print(name + " died")
	entityDeath.emit()
	isDead = true
	#if modelController: await modelController.startedDeathAnim
	queue_free()


func move_towards(targetPos : Vector3, delta : float, speed : float, accel : float = 60) -> void:
	var dir : Vector3 = (targetPos - global_position).normalized()
	velocity = velocity.move_toward(dir * speed, accel * delta)
	move_and_slide()


func face_velocity(delta : float, turnSpeed : float = 5.0 ) -> void:
	var horizontalVel : Vector3 = Vector3(velocity.x, 0, velocity.z)
	if horizontalVel.length_squared() < 0.001: return

	var targetRot : float = atan2(horizontalVel.x, horizontalVel.z)
	model.rotation.y = lerp_angle(model.rotation.y, targetRot, turnSpeed * delta)