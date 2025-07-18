extends Node3D

@onready var animator : AnimationPlayer = $AnimationPlayer
@onready var menu : Control = $elevatorMenu

var checkForSkip : bool = false
var isExiting : bool = false

var exitTriggered : bool = false

func _ready():
    GameManager.player.freeze()
    GameManager.player.hide()

    remove_child(menu)
    GameManager.add_ui(menu)

    CameraManager.set_active_cam($PhantomCamera3D, 0)


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
                create_tween().tween_property(menu, "modulate:a", 0, 0.5)
                animator.play("move")

                await animator.animation_finished
                if !isExiting: exit_elevator()
                walkout_anim()


func trigger_exit() -> void: exitTriggered = true


func exit_elevator() -> void: 
    isExiting = true
    await GameManager.fadeout_screen(2.0, Color.WHITE, GameManager.fadeTargets.AREA)
    queue_free()
    


func walkout_anim() -> void:
    var model : Node3D = $elevator/SophiaSkin
    model.move()
    await create_tween().tween_property(model, "position:z", 10.0, 2.0).finished

