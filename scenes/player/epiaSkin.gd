@tool
class_name EpiaSkin extends Node3D

@export_tool_button("Mercury Mode", "Node3D") 
var mercModeButton : Callable = enter_merc_mode

@export_tool_button("Normal Mode", "Node3D") 
var normModeButton : Callable = enter_norm_mode

@onready var animation_tree = %AnimationTree
@onready var state_machine : AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback")

@onready var cameraEggTimer : Timer = $cameraEggTimer
@onready var lookAt : LookAtModifier3D = %lookAt

func set_look_target(target : Node3D) -> void: lookAt.target_node = target.get_path()
func clear_look_target() -> void: lookAt.target_node = ""

func idle():
	state_machine.travel("epia_idle")

func move():
	state_machine.travel("epia_run")

func fall():
	state_machine.travel("epia_fall")

func jump():
	state_machine.travel("epia_jump")

func edge_grab():
	state_machine.travel("epia_edge")

func wall_slide():
	state_machine.travel("WallSlide")

func weird_idle():
	state_machine.travel("epia_idleStrange")

func roll():
	state_machine.travel("epia_roll")


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