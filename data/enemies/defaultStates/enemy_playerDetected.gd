extends EntityState

@export var moveSpeed : float = 4.0
@export var loseSightDelay : float = 2.0
@export var turnSpeed : float = 5.0

const DETECT_POPUP : PackedScene = preload("res://ui/ui_enemyDetect.tscn")
var loseTimer : float = 0

func enter() -> void:
    if entity is Entity:
        entity.targetPosition.add_child(DETECT_POPUP.instantiate())
    loseTimer = loseSightDelay

func physics_update(delta : float) -> void:
    var playerPos : Vector3 = GameManager.player.global_transform.origin
    var dir : Vector3 = (playerPos - entity.global_transform.origin).normalized()
    entity.velocity = dir * moveSpeed
    entity.move_and_slide()

    if entity is Entity:
        entity.face_velocity(delta, turnSpeed)
        if entity.targetArea:
            var inTarget : bool = entity.targetArea.get_overlapping_bodies().has(GameManager.player)
            if inTarget:
                return
                stateMachine.transition_to("Attack")
        
        if entity is Enemy:
            if entity.detectionArea:
                if !entity.detectionArea.get_overlapping_bodies().has(GameManager.player):
                    loseTimer -= delta
                    if loseTimer <= 0:
                        stateMachine.transition_to("Idle")
            else:
                loseTimer = loseSightDelay
