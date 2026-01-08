extends HealthComponent
class_name PlayerHealthComponent

const HEALTH_PER_UPGRADE : float = 25
const HP_REFILL_TIME : float = 10.0

var refillTimer : Timer

@export var healthUpgrades : int = 3 :
    set(val):
        healthUpgrades = val
        calc_mhp()
        reset_health()

func _ready(): 
    calc_mhp()
    reset_health()
    setup_timer()


func calc_mhp() -> float:
    maxHealth = healthUpgrades * HEALTH_PER_UPGRADE
    return maxHealth


func setup_timer() -> void:
    refillTimer = Timer.new()
    refillTimer.wait_time = HP_REFILL_TIME
    refillTimer.timeout.connect(reset_health)
    hpChanged.connect(func(_h : float): if health != maxHealth: refillTimer.start())
    add_child(refillTimer)