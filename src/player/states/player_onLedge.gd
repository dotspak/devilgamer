extends PlayerState

var acceptInput : bool = false
var point : Vector3
var normal : Vector3

func enter() -> void:
    acceptInput = false
    player.velocity = Vector3.ZERO
    await position_player_model()
    await get_tree().create_timer(0.2).timeout
    acceptInput = true

func position_player_model() -> void:
    point = player.get_ledge_point()
    normal = -player.ledgeRayHori.get_collision_normal()
    # player.model.rotation.y = atan2(normal.x, normal.z)

    var TW : Tween = create_tween().set_trans(Tween.TRANS_SINE).set_parallel()
    TW.tween_property(player, "global_position", point, 0.2)
    player.disable_collision()
    player.model.edge_grab()
    await TW.finished

func physics_update(_delta : float) -> void:
    if normal:
        player.model.rotation.y = lerp_angle(
            player.model.rotation.y, atan2(normal.x, normal.z), 0.3)
    if acceptInput: ledge_input()

func ledge_input() -> void:
    player.movement_input()

    # fall off the ledge
    if player.moveInput == Vector2.DOWN:
        acceptInput = false
        player.velocity += -player.model.basis.z.normalized() * 4
        stateMachine.transition_to("fall")

    # climb up the ledge
    elif player.moveInput == Vector2.UP:
        acceptInput = false
        
        var finalPos : Vector3 = player.ledgeRayVert.get_collision_point()
        finalPos += player.ledgeRayHori.get_collision_normal() * 0.2

        var TW = create_tween().set_trans(Tween.TRANS_SINE)
        TW.tween_property(player, "global_position:y", finalPos.y, 0.2)
        player.model.jump()
        await TW.finished
        stateMachine.transition_to("idle")

func exit() -> void:
    player.enable_collision()
    player.canGrabLedge = false