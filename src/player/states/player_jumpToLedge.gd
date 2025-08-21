extends PlayerState

const jumpTime : float = 0.2
var point : Vector3

func enter() -> void:
    player.disable_collision()
    player.model.jump()
    point = player.get_ledge_point()
    player.velocity = Vector3.ZERO

    var TW : Tween = create_tween().set_trans(Tween.TRANS_SINE)
    TW.tween_property(player, "position", point, jumpTime)
    await TW.finished
    player.apply_floor_snap()
    stateMachine.transition_to("onLedge")
