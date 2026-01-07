extends PlayerState

var acceptInput : bool = false
var point : Vector3
var normal : Vector3

func enter() -> void:
    acceptInput = false
    player.velocity = Vector3.ZERO
    await position_player_model()
    await player.climb_up_ledge()
    acceptInput = true


func position_player_model() -> void:
    point = player.get_ledge_point()
    normal = -player.ledgeRayHori.get_collision_normal()

    var TW : Tween = create_tween().set_trans(Tween.TRANS_SINE).set_parallel()
    TW.tween_property(player, "global_position", point, 0.2)
    player.disable_collision()
    player.model.edge_grab()
    await TW.finished
    await get_tree().create_timer(0.05).timeout


func exit() -> void:
    player.enable_collision()
    player.canGrabLedge = false