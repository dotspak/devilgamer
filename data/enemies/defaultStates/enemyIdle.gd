extends EntityState

@export var roamInterval : float = 2.0
@export var intervalVariance : float = 0
@export var roamSpeed : float = 2.0
@export var roamSpace : float = 2.0
@export var turnSpeed : float = 5.0
@export var moveY : bool = false

var timer : float = 0
var roamDirection : Vector3
var isStopped : bool = false

func enter() -> void:
	if entity is Enemy:
		entity.tookDamage.connect(quick_detect)
	timer = roamInterval + randf_range(-intervalVariance, intervalVariance)
	roamDirection = Vector3.ZERO


func physics_update(delta : float) -> void:
	timer -= delta
	if entity is Entity: entity.face_velocity(delta, turnSpeed)
	if timer <= 0:
		if !isStopped: 
			isStopped = true
			roamDirection = Vector3.ZERO
		else:
			isStopped = false
			
			var yVel : float = randf() - 0.5 if moveY else 0.0
			roamDirection = Vector3(randf() - 0.5, yVel, randf() - 0.5).normalized()
		
		var t : float = roamInterval if !isStopped else roamSpace
		timer = t + randf_range(-intervalVariance, intervalVariance)

	entity.velocity = roamDirection * roamSpeed
	entity.move_and_slide()

	var playerDetected : bool = false
	if entity is Enemy:
		if entity.detectionArea: playerDetected = entity.detectionArea.get_overlapping_bodies().has(GameManager.player)
		else: playerDetected = true

	if playerDetected: quick_detect()


func exit() -> void:
	if entity is Enemy:
		entity.tookDamage.disconnect(quick_detect)


func quick_detect() -> void: stateMachine.transition_to("PlayerDetected")
