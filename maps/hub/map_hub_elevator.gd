extends Node3D

var audio : AudioStream = load("res://assets/audio/bgm/bgm_elevator.ogg")

@onready var animator : AnimationPlayer = $AnimationPlayer
@onready var menu : Control = $elevatorMenu

var checkForSkip : bool = false
var isExiting : bool = false

var exitTriggered : bool = false

func _ready():
	$bgs.play()
	create_tween().tween_property($bgs, "volume_linear", 0.7, 0.5).from(0)

	set_process(false)
	GameManager.player.freeze()
	GameManager.player.hide()

	remove_child(menu)
	GameManager.add_ui(menu)
	CameraManager.set_active_cam($PhantomCamera3D, 0)
	AudioManager.play_bgm(audio, 1, 1, 1)

	await GameManager.fadein_screen(0.5, Utils.ELEVATOR_FADE_COLOR)

	animator.play("start")
	await animator.animation_finished
	set_process(true)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("confirm"): trigger_exit()

	if exitTriggered && !isExiting:
		if Input.is_action_just_pressed("confirm"):
			if checkForSkip && !isExiting:
				set_process(false)
				checkForSkip = false
				exit_elevator()
		else:
			if !animator.is_playing():
				checkForSkip = true
				menu_fade_out()
				animator.play("move")

				await animator.animation_finished
				if !isExiting: exit_elevator()
				walkout_anim()


func menu_fade_out() -> void:
	var TW : Tween = create_tween()
	TW.tween_property(menu, "modulate:a", 0, 0.5)
	TW.finished.connect(menu.queue_free)

func trigger_exit() -> void: 
	if exitTriggered: return
	AudioManager.fade_bgm(2.0)
	exitTriggered = true


func exit_elevator() -> void: 
	isExiting = true
	await GameManager.fadeout_screen(2.0, Utils.ELEVATOR_FADE_COLOR, GameManager.fadeTargets.AREA)
	GameManager.load_area(GameManager.startingArea, "", Utils.ELEVATOR_FADE_COLOR)
	queue_free()
	


func walkout_anim() -> void:
	var model : Node3D = $elevator/SophiaSkin
	model.move()
	await create_tween().tween_property(model, "position:z", 10.0, 2.0).finished
