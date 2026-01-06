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

var softTarget : Node3D = null
var lockedTarget : Node3D = null
var validTargets : Dictionary[Node3D, bool] = {}

func has_target() -> bool: return softTarget != null
func is_targettable(node : Node) -> Node3D: return node.get_node_or_null("TargetPoint")
func is_valid_target(target : Node3D) -> bool: return is_instance_valid(target) && validTargets[target]

func _ready() -> void:
	targetRadius.body_entered.connect(_on_body_entered)
	targetRadius.body_exited.connect(_on_body_exited)
	reticle.set_active(false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("lock_on"):
		toggle_lock()


func _physics_process(_delta: float) -> void:
	remove_invalid_targets()

	# remove locked target if it becomes invalid
	if lockedTarget && is_valid_target(lockedTarget): lockedTarget = null

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
		validTargets[body] = true


func _on_body_exited(body : Node3D) -> void:
	if validTargets.has(body):validTargets.erase(body)
	if lockedTarget == body: lockedTarget = null
	if softTarget == body: softTarget = null


func remove_invalid_targets() -> void:
	for target in validTargets.keys():
		if !is_instance_valid(target) || !is_valid_target(target):
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

	for target in validTargets.keys():
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
	if lockedTarget:
		print("unlocking from the target")
		reticle.lock_off()
		lockedTarget = null
		return
	
	if softTarget && is_valid_target(softTarget):
		print("locking onto the target")
		reticle.lock_on()
		lockedTarget = softTarget


func update_reticle() -> void:
	if !softTarget:
		reticle.set_active(false)
		return

	reticle.set_active(true)
	reticle.set_world_pos(get_target_point(softTarget))
