# cameraManager.gd ------------------------------------------
# controls all cameras in the game. Has logic to set a camera
# as the active one, and can control the player's cameras.
extends Node

var playerMainCam : PhantomCamera3D
var playerLockCam : PhantomCamera3D
var currentCam : PhantomCamera3D


func set_active_cam(cam : PhantomCamera3D, duration : float = 1.0) -> void:
	if currentCam: currentCam.priority = 0
	currentCam = cam
	currentCam.priority = 2
	currentCam.tween_duration = duration

	playerMainCam.priority = 0
	playerLockCam.priority = 0

	await currentCam.tween_completed


func enable_main_cam(duration : float = -1.0) -> void:
	if !playerMainCam: return

	if currentCam: currentCam.priority = 0
	playerMainCam.priority = 1
	playerLockCam.priority = 0

	var prevDuration : float = playerMainCam.tween_duration
	if duration >= 0:
		playerMainCam.tween_duration = duration
		
	await playerMainCam.tween_completed
	playerMainCam.tween_duration = prevDuration


func enable_lock_cam(duration : float = -1.0) -> void:
	if !playerLockCam: return

	if currentCam: currentCam.priority = 0
	playerMainCam.priority = 0
	playerLockCam.priority = 1

	var prevDuration : float = playerLockCam.tween_duration
	if duration >= 0:
		playerLockCam.tween_duration = duration

	await playerLockCam.tween_completed
	playerLockCam.tween_duration = prevDuration


func create_conversation_camera(npc : Node3D, margin : float = 2.5, sideOffset : float = 1.5, verticalBiasFactor : float = 0.7) -> Node3D:
	var player = GameManager.player
	var camera : PhantomCamera3D = PhantomCamera3D.new()
	var midpoint : Vector3 = npc.global_transform.origin.lerp(player.global_transform.origin, 0.4)

	camera.set_tween_duration(PhantomCameraTween.TransitionType.SINE)
	
	var dir = (npc.global_transform.origin - player.global_transform.origin)
	dir.y = 0
	dir = dir.normalized()

	var side : Vector3 = Vector3(-dir.z, 0, dir.x)
	var dist : float = player.global_transform.origin.distance_to(npc.global_transform.origin)

	# get the which side the player is on
	var toPlayer : Vector3 = player.global_transform.origin - npc.global_transform.origin
	var rightDot : float = side.normalized().dot(toPlayer.normalized())
	var signedOffset = -(sideOffset * sign(rightDot))

	npc.add_child(camera)

	var camPos : Vector3 = midpoint \
		- dir * (dist * 0.75 + margin) \
		+ side * signedOffset \
		+ Vector3.UP * (dist * 0.5 + margin * 0.5)

	camera.global_transform.origin = camPos

	# angles the camera up based on the NPC's height
	var heightDiff : float = npc.global_transform.origin.y - player.global_transform.origin.y
	var tiltAdjustment : Vector3 = Vector3.UP * (heightDiff * verticalBiasFactor)

	camera.look_at(midpoint + tiltAdjustment, Vector3.UP)

	return camera
