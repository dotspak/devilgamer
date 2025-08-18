class_name EpiaSkin extends Node3D

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
