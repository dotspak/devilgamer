@tool
extends Node3D
class_name EpiaSkin

@export_tool_button("Mercury Mode", "Node3D") 
var mercModeButton : Callable = enter_merc_mode

@export_tool_button("Normal Mode", "Node3D") 
var normModeButton : Callable = enter_norm_mode

@export var testAttackType : PlayerAttackData.AttackType
@export_tool_button("Test Attack", "Node3D")
var testAttackButton : Callable = func():
	cast(testAttackType, 0.2)
	await get_tree().create_timer(0.2).timeout
	attack(testAttackType, 0.2)

@export_range(0, 1) var speed : float = 0 :
	set(val):
		speed = clamp(val, 0, 1)
		if Engine.is_editor_hint() || is_node_ready():
			tree.set("parameters/runTimeScale/scale", speed)
			tree.set("parameters/runSpeed/blend_amount", speed)
			tree.set("parameters/weaponState/none/runBlend/blend_amount", speed)

enum WEAPONSTATES {None, Gun, OneHand, TwoHand}
@export var currentWeapon : WEAPONSTATES = WEAPONSTATES.None :
	set(val):
		currentWeapon = val
		if Engine.is_editor_hint() || is_node_ready():
			weaponIdle()


@onready var animation_tree = %AnimationTree
@onready var state_machine : AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback")

@onready var tree : AnimationTree = %AnimationTree2
@onready var weaponState : AnimationNodeStateMachinePlayback = tree.get("parameters/weaponState/playback")

@onready var cameraEggTimer : Timer = $cameraEggTimer
@onready var lookAt : LookAtModifier3D = %lookAt
@onready var weaponSlot : Node3D = %weaponHolder

func _ready() -> void:
	speed = 0

func clear_look_target() -> void: lookAt.target_node = ""
func set_look_target(target : Node3D, secondaryRotation : bool = true) -> void: 
	lookAt.use_secondary_rotation = secondaryRotation
	lookAt.target_node = target.get_path() if target else "" as NodePath


func idle():
	tree.set("parameters/edgeShot/request", AnimationNodeOneShot.OneShotRequest.ONE_SHOT_REQUEST_FADE_OUT)
	tree.set("parameters/fallshot/request", AnimationNodeOneShot.OneShotRequest.ONE_SHOT_REQUEST_FADE_OUT)
	tree.set("parameters/fallShot/request", AnimationNodeOneShot.OneShotRequest.ONE_SHOT_REQUEST_FADE_OUT)


func move():
	pass
	#state_machine.travel("run")


func fall():
	#state_machine.travel("fall")
	tree.set("parameters/fallShot/request", AnimationNodeOneShot.OneShotRequest.ONE_SHOT_REQUEST_FIRE)
	tree.set("parameters/edgeShot/request", AnimationNodeOneShot.OneShotRequest.ONE_SHOT_REQUEST_FADE_OUT)
	tree.set("parameters/jumpShot/request", AnimationNodeOneShot.OneShotRequest.ONE_SHOT_REQUEST_FADE_OUT)


func jump():
	#state_machine.travel("jump")
	tree.set("parameters/jumpShot/request", AnimationNodeOneShot.OneShotRequest.ONE_SHOT_REQUEST_FIRE)
	tree.set("parameters/edgeShot/request", AnimationNodeOneShot.OneShotRequest.ONE_SHOT_REQUEST_FADE_OUT)
	tree.set("parameters/fallshot/request", AnimationNodeOneShot.OneShotRequest.ONE_SHOT_REQUEST_FADE_OUT)
	tree.set("parameters/rollShot/request", AnimationNodeOneShot.OneShotRequest.ONE_SHOT_REQUEST_FADE_OUT)


func edge_grab():
	#state_machine.travel("edge")
	tree.set("parameters/edgeShot/request", AnimationNodeOneShot.OneShotRequest.ONE_SHOT_REQUEST_FIRE)
	tree.set("parameters/fallshot/request", AnimationNodeOneShot.OneShotRequest.ONE_SHOT_REQUEST_FADE_OUT)
	tree.set("parameters/fallShot/request", AnimationNodeOneShot.OneShotRequest.ONE_SHOT_REQUEST_FADE_OUT)

func wall_slide():
	state_machine.travel("WallSlide")


func weird_idle():
	state_machine.travel("idleStrange")


func land():
	tree.set("parameters/jumpShot/request", AnimationNodeOneShot.OneShotRequest.ONE_SHOT_REQUEST_FADE_OUT)
	tree.set("parameters/edgeShot/request", AnimationNodeOneShot.OneShotRequest.ONE_SHOT_REQUEST_FADE_OUT)
	tree.set("parameters/fallShot/request", AnimationNodeOneShot.OneShotRequest.ONE_SHOT_REQUEST_FADE_OUT)
	tree.set("parameters/landShot/request", AnimationNodeOneShot.OneShotRequest.ONE_SHOT_REQUEST_FIRE)


func roll():
	#state_machine.travel("roll")
	tree.set("parameters/rollShot/request", AnimationNodeOneShot.OneShotRequest.ONE_SHOT_REQUEST_FIRE)
	

func weaponString() -> String:
	var string : String = ""
	match(currentWeapon):
		WEAPONSTATES.Gun: string = "gun_"
		WEAPONSTATES.OneHand: string = "oneHand_"
		WEAPONSTATES.TwoHand: string = "twoHand_"
		_: ""
	return string


func cast(_type : PlayerAttackData.AttackType = PlayerAttackData.AttackType.SWING, _speed : float = 1.0) -> void:
	print("casting with type " + PlayerAttackData.AttackType.keys()[_type])
	tree.set("parameters/weaponState/cast/castSpeed/scale", _speed)
	tree.set("parameters/weaponState/cast/castType/blend_position", _type)
	weaponState.travel("cast")


func attack(_type : PlayerAttackData.AttackType = PlayerAttackData.AttackType.SWING, _speed : float = 1.0) -> void:
	# animation_tree.set("parameters/StateMachine/attack/TimeScale/scale", attackSpeed)
	# state_machine.travel("attack")

	# weaponSlot.show()
	# await animation_tree.animation_finished
	# weaponSlot.hide()
	print("attacking with type " + PlayerAttackData.AttackType.keys()[_type])
	tree.set("parameters/weaponState/attack/attackSpeed/scale", _speed)
	tree.set("parameters/weaponState/attack/attackType/blend_position", _type)
	weaponState.travel("attack")

func weaponIdle() -> void: 
	weaponState.travel("idle")

func clear_weapon_holder() -> void:
	for n in weaponSlot.get_children():
		n.queue_free()


func get_current_anim() -> String: return state_machine.get_current_node()


func enter_merc_mode() -> void:
	$model/Armature/Skeleton3D/armCorrupt.show()
	$model/Armature/Skeleton3D/armPlate.show()
	$model/Armature/Skeleton3D/horns.show()
	$model/Armature/Skeleton3D/hornPlate.show()

	$model/Armature/Skeleton3D/armL.hide()

func enter_norm_mode() -> void:
	$model/Armature/Skeleton3D/armCorrupt.hide()
	$model/Armature/Skeleton3D/armPlate.hide()
	$model/Armature/Skeleton3D/horns.hide()
	$model/Armature/Skeleton3D/hornPlate.hide()

	$model/Armature/Skeleton3D/armL.show()


func show_hand_attachment() -> void: %handAttachment.show()
func hide_hand_attachment() -> void: %handAttachment.hide()

func attach_to_hand(node : Node3D) -> void:
	node.reparent(weaponSlot)
	node.transform = weaponSlot.transform
