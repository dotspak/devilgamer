# targetter.gd -----------------------------
# Handles logic for acquiring a target for the player
extends Node
class_name PlayerTargetter

@export_category("Node References")
@export var playerCamera : PhantomCamera3D
@export var targetRadius : Area3D
@export var reticle : Reticle

@export_category("Settings")
@export_range(0,1, 0.01) var minDotToTarget : float = 0.7
@export var distanceWeight : float = 0.15

var softTarget : Node3D = null :
	set(val):
		softTarget = val
		foundTarget.emit(softTarget)
var lockedTarget : Node3D = null :
	set(val):
		lockedTarget = val
		if !lockedTarget:
			reticle.lock_off()
			owner.lock_off()

var validTargets : Array[Node3D] = []

signal foundTarget(target : Node3D)

func has_target() -> bool: return softTarget != null
func is_targettable(node : Node) -> Node3D: return node.get_node_or_null("TargetPoint")
func is_valid_target(target : Node3D) -> bool: return is_instance_valid(target) && validTargets.has(target)

func _ready() -> void:
	targetRadius.body_entered.connect(_on_body_entered)
	targetRadius.body_exited.connect(_on_body_exited)
	reticle.set_active(false)


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("lock_on"):
		toggle_lock()


func _physics_process(_delta: float) -> void:
	remove_invalid_targets()

	# remove locked target if it becomes invalid
	if lockedTarget && !is_valid_target(lockedTarget): lockedTarget = null

	# target choosing: use locked by default, otherwise determine the target
	if lockedTarget: softTarget = lockedTarget
	else: softTarget = pick_best_target()

	update_reticle()

# ------------------------------------
# Target Validation
# ------------------------------------
func _on_body_entered(body : Node3D) -> void:
	if is_targettable(body):
		print(body.name)
		validTargets.append(body)


func _on_body_exited(body : Node3D) -> void:
	if validTargets.has(body): validTargets.erase(body)
	if lockedTarget == body: lockedTarget = null
	if softTarget == body: softTarget = null


func remove_invalid_targets() -> void:
	for target in validTargets:
		if !is_valid_target(target):
			validTargets.erase(target)
			if lockedTarget == target: lockedTarget = null
			if softTarget == target: softTarget = null
 

# ------------------------------------
# Target Selection
# ------------------------------------
func pick_best_target() -> Node3D:
	if validTargets.is_empty(): return null

	var camPos : Vector3 = playerCamera.global_position
	var camForward : Vector3 = -playerCamera.global_basis.z
	var bestTarget : Node3D = null
	var bestScore := -INF

	for target in validTargets:
		if !is_valid_target(target): continue

		var targetPos : Vector3 = get_target_point(target)
		var toTarget : Vector3 = targetPos - camPos
		var distance : float = toTarget.length()
		if distance <= 0.001: continue

		var dir : Vector3 = toTarget / distance
		var dot : float = camForward.dot(dir)

		if dot < minDotToTarget: continue

		var score : float = dot - (distance * distanceWeight / 100.0)
		if score > bestScore:
			bestScore = score
			bestTarget = target

	return bestTarget


func get_target_point(target : Node3D) -> Vector3:
	var point := is_targettable(target)
	if point && point is Node3D: return (point as Node3D).global_position
	return target.global_position


func toggle_lock() -> void:
	# lock off from the target
	if lockedTarget:
		print("unlocking from the target")
		lockedTarget = null
		reticle.lock_off()
		owner.lock_off()
	
	# lock on to the target
	elif softTarget && is_valid_target(softTarget):
		print("locking onto the target")
		lockedTarget = softTarget
		reticle.lock_on()
		owner.lock_on()


func update_reticle() -> void:
	if !softTarget:
		reticle.set_active(false)
		return

	reticle.set_world_pos(get_target_point(softTarget))
	reticle.set_active(true)
