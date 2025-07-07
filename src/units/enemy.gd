extends Unit
class_name Enemy

var battleScript : EnemyScript

func enter_selecting_phase() -> void:
    battleTimer.stop()
    phase = Phase.SELECTING
    battleScript.choose_action()
    enter_casting_phase()