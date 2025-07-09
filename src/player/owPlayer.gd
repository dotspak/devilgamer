extends Entity
class_name OWPlayer

# ledge controls
const LEDGE_BIAS : Vector3 = Vector3(-0.3, -0.8, -0.3)
const LEDGE_X = 0.2
const LEDGE_Y = -0.8
const LEDGE_Z = 0.2

# particles
const LAND_PARTICLE : PackedScene = preload("res://scenes/player/pe_landParticles.tscn")
const JUMP_PARTICLE : PackedScene = preload("res://scenes/player/pe_jumpParticles.tscn")

# camera max/mins
const minYaw : float = 0
const maxYaw : float = 360
const minPitch : float = -89.9
const maxPitch : float = 50

@export_category("Camera Controls")
@export_range(0,1) var camSensitivity : float = 0.05

@export_group("Movement")
@export var speed : float = 8
@export var accel : float = 60
@export var accel_airScale : float = 0.3
@export var accel_idleScale : float = 2.0
@export var rotationSpeed : float = 10
@export var jumpStrength : float = 8
@export var jumpDist : float = 4
@export var climbSpeed : float = 2

@export_group("Flair")
@export var sounds : Dictionary[String, Node]

@onready var stateMachine : StateMachine = %StateMachine

@onready var camera : Camera3D = %Camera3D
@onready var model : Node3D = %SophiaSkin
@onready var jumpCheck : RayCast3D = %jumpCheck

@onready var stepParticles : GPUParticles3D = %stepParticles
@onready var fallingParticles : GPUParticles3D = %fallingParticles

@onready var ledgeRayVert : RayCast3D = %ledgeRayVert
@onready var ledgeRayHori : RayCast3D = %ledgeRayHori
@onready var ledgeRayAnti : RayCast3D = %ledgeRayAnti
@onready var stairRayDown : RayCast3D = %stairRayDown
@onready var stairRayAhead : RayCast3D = %stairRayAhead

@onready var basicAttackCooldown : Timer = %basicAttackCooldown

@onready var pCamHost : PhantomCameraHost = %PhantomCameraHost
@onready var mainCam : PhantomCamera3D = %mainCam
@onready var lockCam : PhantomCamera3D = %lockCam

var isRespawning : bool = false
var inputAllowed : bool = true

var moveInput : Vector2 = Vector2.ZERO
var moveDir : Vector3 = Vector3.ZERO
var lastMoveDir : Vector3 = Vector3.BACK

var useMouseInput : bool = true
var camMouseInput : Vector2 = Vector2.ZERO
var resetCamera : bool = false

var isJumping : bool = true
var gravity : float = -40
var airTimer : float = 0
var canGrabLedge : bool = true

var lastSafePosition : Vector3 = Vector3.ZERO :
	set(val):
		if headInWater: return
		lastSafePosition = val

var inWater : bool = false
var headInWater : bool = false
var maxBreath : float = 5 :
	set(val):
		maxBreath = val
		breathTimer = maxBreath
		print("updating max breath")
		GameManager.change_max_breath(maxBreath)

var breathTimer : float = 0 :
	set(val):
		breathTimer = val
		GameManager.update_breath_bar(breathTimer)
		if breathTimer <= 0:
			respawn()

# stair detection variables
const MAX_STEP_HEIGHT : float = 0.5
var snappedToStairsLastFrame : bool = false
var lastFrameOnFloor : float = -INF

var currentLadder : Area3D = null

var targetIndicator : Node3D = null
var isLockedOn : bool = false


func _ready() -> void:
	if get_tree().debug_collisions_hint: %ledgePoint.show()
	else: %ledgePoint.hide()

	GameManager.change_max_breath(maxBreath)

	mainCam.priority = 1
	lockCam.priority = 0
	fallingParticles.emitting = false
	stepParticles.emitting = false


func _unhandled_input(event: InputEvent) -> void:
	if inputAllowed:
		# handles mouse camera control
		if event is InputEventMouseMotion && Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			if inputAllowed:
				var camRotation : Vector3 = mainCam.get_third_person_rotation_degrees()

				camRotation.x -= event.relative.y * camSensitivity
				camRotation.x = clampf(camRotation.x, minPitch, maxPitch)
				
				camRotation.y -= event.relative.x * camSensitivity
				camRotation.y = wrapf(camRotation.y, minYaw, maxYaw)

				mainCam.set_third_person_rotation_degrees(camRotation)

		# handles camera lock on/centering camera
		if Input.is_action_just_pressed("center_camera"): center_camera()
		elif Input.is_action_just_released("center_camera"): skillTarget = null
		
		# handles player interaction
		if Input.is_action_just_pressed("interact"):
			for area in get_tree().get_nodes_in_group("interactable"):
				if area is Area3D:
					if area.overlaps_body(self):
						interact(area.get_parent())


func interact(node : Interactable) -> void:
	print("interaction with ", node)
	disable_input()

	node.hide_interact_bubble(self)

	node.run_interaction()
	await node.interactionFinished

	node.display_interact_bubble(self)
	enable_input()


func _physics_process(delta: float) -> void:
	if inputAllowed:
		# DEBUG INPUTS FOR PLAYER ----------------
		if GameManager.DEBUG_MODE:
			# debug hover
			if Input.is_action_pressed("jump"):
				airTimer = 0
				global_position.y += 0.3
				gravity = 0
			else:
				gravity = -40
		
		if isLockedOn:
			var targetBodies : Array[Node3D] = targetArea.get_overlapping_bodies()
			targetBodies.erase(self)

			if !targetBodies.has(skillTarget):
				print("looking for new target")
				skillTarget = get_closest_target()
		
		# handle drowning logic
		if headInWater: breathTimer -= delta

		# controller camera
		var lookX : float = Input.get_action_strength("look_right") - Input.get_action_strength("look_left")
		var lookY : float = Input.get_action_strength("look_down") - Input.get_action_strength("look_up")

		if abs(lookX) > 0.05 || abs(lookY) > 0.05:
			var camRotation : Vector3 = mainCam.get_third_person_rotation_degrees()

			camRotation.x -= lookY * camSensitivity * 35
			camRotation.x = clampf(camRotation.x, minPitch, maxPitch)
			
			camRotation.y -= lookX * camSensitivity * 35
			camRotation.y = wrapf(camRotation.y, minYaw, maxYaw)

			mainCam.set_third_person_rotation_degrees(camRotation)
	
	if !movementAllowed: velocity = lerp(velocity, Vector3.ZERO, stopMoveWeight)

	# checks when the player is on the floor
	if is_on_floor():
		if jumpCheck.is_colliding() && !is_head_underwater(): 
			lastSafePosition = global_position
		
		lastFrameOnFloor = Engine.get_physics_frames()

	# moves the character around
	if !snap_up_to_stairs(delta):
		move_and_slide()
		snap_down_to_stairs()
	
	if moveDir.length() > 0.2 && stateMachine.is_state("run"): lastMoveDir = moveDir


func movement_input() -> bool:
	if !inputAllowed || !movementAllowed: return false

	var forward : Vector3 = camera.global_basis.z
	var right : Vector3 = camera.global_basis.x
	moveInput = Input.get_vector("left", "right", "up", "down")
	moveDir = forward * moveInput.y + right * moveInput.x
	return moveInput != Vector2.ZERO
	

func move(delta : float) -> void:
	if !movementAllowed: return

	moveDir.y = 0
	moveDir = moveDir.normalized()

	velocity = velocity.move_toward(moveDir * speed, (
		accel * accel_idleScale if moveInput == Vector2.ZERO else accel)* delta)
	
	var angle : float = Vector3.BACK.signed_angle_to(lastMoveDir, Vector3.UP)
	model.rotation.y = lerp_angle(model.rotation.y, angle, rotationSpeed * delta)


func is_surface_too_steep(normal : Vector3) -> bool: return normal.angle_to(Vector3.UP) > floor_max_angle
func run_body_test_motion(from : Transform3D, motion : Vector3, result = null) -> bool:
	if !result: result = PhysicsTestMotionResult3D.new()
	var params = PhysicsTestMotionParameters3D.new()
	params.from = from
	params.motion = motion
	return PhysicsServer3D.body_test_motion(get_rid(), params, result)


func snap_down_to_stairs() -> void:
	var didSnap : bool = false
	var wasOnFloor = Engine.get_physics_frames() - lastFrameOnFloor == 1
	var floorBelow : bool = stairRayDown.is_colliding() && !is_surface_too_steep(stairRayDown.get_collision_normal())
	if !is_on_floor() && velocity.y <= 0 && (wasOnFloor || snappedToStairsLastFrame) && floorBelow:
		var bodyTestResult : PhysicsTestMotionResult3D = PhysicsTestMotionResult3D.new()
		if run_body_test_motion(global_transform, Vector3(0, -MAX_STEP_HEIGHT, 0), bodyTestResult):
			var translateY = bodyTestResult.get_travel().y
			position.y += translateY
			apply_floor_snap()
			didSnap = true
		snappedToStairsLastFrame = didSnap


func snap_up_to_stairs(delta : float) -> bool:
	if !is_on_floor() && !snappedToStairsLastFrame: return false

	var expectedMoveMotion : Vector3 = velocity * Vector3(1, 0, 1) * delta
	var stepPosWithClearance : Transform3D = global_transform.translated(expectedMoveMotion + Vector3(0, MAX_STEP_HEIGHT * 2, 0))
	var downCheckResult : PhysicsTestMotionResult3D = PhysicsTestMotionResult3D.new()
	
	if (run_body_test_motion(stepPosWithClearance, Vector3(0, -MAX_STEP_HEIGHT * 2, 0), downCheckResult) &&
		(downCheckResult.get_collider().is_class("StaticBody3D") || downCheckResult.get_collider().is_class("CSGShape3D"))):
			var stepHeight : float = ((stepPosWithClearance.origin + downCheckResult.get_travel()) - global_position).y
			
			if stepHeight > MAX_STEP_HEIGHT || (downCheckResult.get_collision_point() - global_position).y > MAX_STEP_HEIGHT: return false
			
			stairRayAhead.global_position = downCheckResult.get_collision_point() + Vector3(0, MAX_STEP_HEIGHT, 0) + expectedMoveMotion.normalized() * 0.1
			stairRayAhead.force_raycast_update()
			if stairRayAhead.is_colliding() && !is_surface_too_steep(stairRayAhead.get_collision_normal()):
				global_position = stepPosWithClearance.origin + downCheckResult.get_travel()
				apply_floor_snap()
				snappedToStairsLastFrame = true
				return true
	return false


func air_move(delta : float) -> void:
	airTimer += delta
	moveDir.y = 0
	moveDir = moveDir.normalized()
	velocity = velocity.move_toward(moveDir * speed, accel * accel_airScale * delta)


func is_on_ladder() -> bool:
	# already in range of a ladder
	if currentLadder && currentLadder.overlaps_body(self): return true

	# try to find a ladder
	for l : Area3D in get_tree().get_nodes_in_group("climbable"):
		if l.overlaps_body(self):
			currentLadder = l
			return true
	
	# no ladder found
	currentLadder = null
	return false


func climbable_controls() -> void:
	if !currentLadder: return

	var ladderTransform : Transform3D = currentLadder.global_transform
	var relativePos : Vector3 = ladderTransform.affine_inverse() * global_position

	movement_input()
	if moveInput.length() < 0.05:
		velocity = Vector3.ZERO
		return
	
	var ladderUp : Vector3 = ladderTransform.basis.y.normalized()
	var ladderRight : Vector3 = ladderTransform.basis.x.rotated(Vector3(0,1,0), deg_to_rad(-90)).normalized()
	var climbDir : Vector3 = (moveInput.x * ladderRight + (-moveDir.y * ladderUp)).normalized()

	velocity = climbDir * climbSpeed
	global_position = ladderTransform * relativePos


# returns true if a ledge is able to be grabbed
func ledge_detect(inAir : bool = false) -> bool:
	if canGrabLedge:
		ledgeRayAnti.force_raycast_update()
		if ledgeRayAnti.is_colliding(): return false

		ledgeRayHori.force_raycast_update()
		if ledgeRayHori.is_colliding():
			ledgeRayVert.global_position.x = ledgeRayHori.get_collision_point().x
			ledgeRayVert.global_position.z = ledgeRayHori.get_collision_point().z
			ledgeRayVert.force_raycast_update()

			if ledgeRayVert.is_colliding():
				var ledgePoint : Vector3 = get_ledge_point()
				var isInHoriRange : bool = global_position.distance_to(ledgePoint) <= 3
				%ledgePoint.global_position = ledgeRayVert.get_collision_point()
				if isInHoriRange:
					if inAir: return (ledgePoint.y - global_position.y) <= 1.8
					else: return true
	return false


func get_ledge_point() -> Vector3:
	var point : Vector3 = ledgeRayVert.get_collision_point()
	point += LEDGE_BIAS.x * model.global_basis.z
	point.y += LEDGE_BIAS.y
	return point


func jump_check() -> bool: return !jumpCheck.is_colliding() && Vector2(velocity.x, velocity.z).length() >= 6
func apply_gravity(delta : float) -> void: velocity.y += gravity * delta

# just has lock on logic for now, need to re-add camera center
func center_camera() -> void:
	skillTarget = get_closest_target()


func land() -> void:
	var particle : GPUParticles3D = LAND_PARTICLE.instantiate()
	particle.amount = clamp(12 * (1 + airTimer * 2), 12, 100)
	particle.finished.connect(particle.queue_free)
	add_child(particle)
	particle.emitting = true
	airTimer = 0


func jump_particles() -> void:
	var particle : GPUParticles3D = JUMP_PARTICLE.instantiate()
	particle.finished.connect(particle.queue_free)
	model.add_child(particle)
	particle.emitting = true


func disable_collision() -> void: $CollisionShape3D.disabled = true
func enable_collision() -> void: $CollisionShape3D.disabled = false


func respawn() -> void:
	if isRespawning: return

	isRespawning = true
	sounds["void"].play()
	var tempDamp : Vector3 = mainCam.follow_damping_value
	mainCam.follow_damping_value = Vector3(1,1,1)

	await GameManager.fadeout_screen(0.5)

	global_position = lastSafePosition
	velocity = Vector3.ZERO
	mainCam.follow_damping = false
	sounds["respawn"].play()

	await GameManager.fadein_screen(0.5)

	mainCam.follow_damping_value = tempDamp
	mainCam.follow_damping = true
	isRespawning = false


func is_head_underwater() -> bool: return is_underwater() && headInWater
func is_underwater() -> bool: return inWater

func freeze() -> void:
	stateMachine.transition_to("gameFreeze")
	disable_input()
	set_physics_process(false)
	set_process(false)


func un_freeze() -> void:
	stateMachine.transition_to("idle")
	enable_input()
	set_physics_process(true)
	set_process(true)


func disable_input() -> void:
	inputAllowed = false
	moveDir = Vector3.ZERO
	moveInput = Vector2.ZERO
	velocity = Vector3.ZERO


func enable_input() -> void:
	inputAllowed = true


func can_basic_attack() -> bool:
	if inputAllowed:
		if Input.is_action_just_pressed("basic_attack"):
			return !usingSkill && basicAttackCooldown.is_stopped()
	return false


func use_basic_attack() -> void:
	stop_movement()
	var attack : Action = preload("res://scenes/actions/basicAttack.tscn").instantiate()
	castPosition.add_child(attack)
	attack.trigger_skill_shot(self)
	usingSkill = true
	basicAttackCooldown.start()
	attack.actionFinished.connect(func(): 
		movementAllowed = true
		usingSkill = false
	)


# checks if the player can cast the passed skill 
# (for now is just a basic check)
func should_use_skill(_skill = null) -> bool:
	if inputAllowed:
		if Input.is_action_pressed("skill_cast"):
			return super()
	return false


func set_target(t : Entity) -> void:
	if skillTarget && targetIndicator: targetIndicator.queue_free()
	skillTarget = t
	if skillTarget: lock_on()
	else: lock_off()


func show_target_indicator() -> void:
	if !skillTarget: return
	targetIndicator = preload("res://ui/ui_targetIndicator2.tscn").instantiate()
	skillTarget.targetPosition.add_child.call_deferred(targetIndicator)


func hide_target_indicator() -> void: 
	if targetIndicator: 
		targetIndicator.queue_free()


func lock_on() -> void:
	if !isLockedOn: GameManager.enter_focus_ui()
	
	isLockedOn = true
	show_target_indicator()

	lockCam.priority = 1
	mainCam.priority = 0

	# set the target
	lockCam.follow_targets.clear()
	lockCam.set_follow_targets([self, skillTarget])


func lock_off() -> void:
	if !isLockedOn: return

	isLockedOn = false
	hide_target_indicator()

	mainCam.priority = 1
	lockCam.priority = 0
	
	GameManager.exit_focus_ui()


func _on_feet_area_entered(area : Area3D) -> void:
	if area is WaterArea3D:
		print("player has entered water")
		inWater = true


func _on_feet_area_exited(area : Area3D) -> void:
	if area is WaterArea3D:
		for a in %feet.get_overlapping_areas():
			if a is WaterArea3D: return
		
		print("player has left water")
		inWater = false


func _on_head_area_entered(area : Area3D) -> void:
	if area is WaterArea3D:
		print("player head has entered water")
		headInWater = true
		breathTimer = maxBreath
		GameManager.handle_water_change(area.get_water_color())


func _on_head_area_exited(area:Area3D) -> void:
	if area is WaterArea3D:
		for a in %head.get_overlapping_areas():
			if a is WaterArea3D: return
		
		print("head has left water")
		headInWater = false
		GameManager.handle_water_exit()
