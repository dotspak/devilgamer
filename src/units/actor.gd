extends Unit
class_name Actor

var downCount : int = 0 :
    set(val):
        downCount = val
        downCountChanged.emit(downCount)

signal downCountChanged(count : int)
signal revived

# handles downcount change on top of normal unit turn logic
func start_turn() -> void:
    if downCount > 0: 
        downCount -= 1
        if downCount <= 0:
            await _on_revive()
        else:
            await get_tree().create_timer(0.2).timeout
    else: 
        await use_skill()
    end_turn()

# handles when the actor is revived
func _on_revive() -> void:
    revived.emit()
    HP = charSheet.MHP * 0.5
    GameManager.battleScene.handle_actor_revive(self)
    print(charSheet.name, " is revived!")
    await model.play_revive_anim()

# handles the actor specific death
func trigger_death() -> void:
    POW = 0
    RES = 0
    SPD = 0
    await super()
    phase = Phase.DEAD
    battleTimer.wait_time = 4