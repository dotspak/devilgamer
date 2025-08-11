extends Entity
class_name Enemy


@export var detectionArea : Area3D
var initialTransform : Transform3D

func _ready() -> void:
    super()
    initialTransform = global_transform
    

func spawn() -> void:
    global_transform = initialTransform
    stateMachine.transition_to("Idle")
    show()

func deactivate() -> void:
    stateMachine.transition_to("Freeze")
    hide()