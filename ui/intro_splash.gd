extends CanvasLayer

const TIME : float = 0.5

@onready var bg : ColorRect = $bg

func _ready():
    for n : Node in bg.get_children(): n.hide()


func play_splashes() -> void:
    await animate_node(%spakLogo)


func animate_node(node : Control) -> void:
    var finalPos : float = node.position.y
    var tween := create_tween().set_trans(Tween.TRANS_SINE).set_parallel()

    node.show()
    tween.tween_property(node, "position:y", finalPos, TIME).from(finalPos + 20)
    tween.tween_property(node, "modulate:a", 1, TIME).from(0)

    await tween.finished
    await get_tree().create_timer(TIME * 2).timeout

    tween = create_tween().set_trans(Tween.TRANS_SINE).set_parallel()
    tween.tween_property(node, "position:y", finalPos + 20, TIME).from(finalPos)
    tween.tween_property(node, "modulate:a", 0, TIME).from(1)

    await tween.finished
    node.hide()