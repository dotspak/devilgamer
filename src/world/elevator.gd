@tool
extends Interactable
class_name Elevator

@export var ID : String = ""

@onready var animator : AnimationPlayer = $AnimationPlayer
@onready var playerPos : Marker3D = $playerPos

signal elevatorUnlocked(id : String)

func _ready():
    super()
    if !Engine.is_editor_hint():
        if GameFlags.check_elevator(ID): customTypeText = "Ride"
        else: customTypeText = "Unlock"


func enter_elevator() -> void:
    animator.play("doorOpenExtended")
    await animator.animation_finished

    GameManager.player.move_to_position(global_position)
    await GameManager.player.movedToPosition

    var lookAtPos : Vector3 = Vector3(0, cameraOverride.global_position.y, 0)
    GameManager.player.model.look_at(lookAtPos)

    animator.play("doorClose")
    await get_tree().create_timer(0.8).timeout
    await GameManager.fadeout_screen(0.5, Utils.ELEVATOR_FADE_COLOR)

    GameManager.load_elevator()


func exit_elevator() -> void:
    CameraManager.set_active_cam(cameraOverride, 0)
    GameManager.fadein_screen(0.5, Utils.ELEVATOR_FADE_COLOR)
    animator.play("doorOpenExtended")
    await animator.animation_finished

    GameManager.player.move_to_position(playerPos.global_position)
    await GameManager.player.movedToPosition

    animator.play_backwards("doorOpen")
    GameManager.player.camera_to_front()
    CameraManager.enable_main_cam()
    await animator.animation_finished


func unlock_elevator() -> void:
    GameFlags.unlock_elevator(ID)
    $chime.play()
    customTypeText = "ride"
    elevatorUnlocked.emit(ID)