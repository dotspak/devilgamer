extends HealthComponent
class_name PlayerHealthComponent

const HEALTH_PER_UPGRADE : float = 25

@export var healthUpgrades : int = 3 :
    set(val):
        healthUpgrades = val
        calc_mhp()
        reset_health()

func _ready(): 
    calc_mhp()
    reset_health()

func calc_mhp() -> float:
    maxHealth = healthUpgrades * HEALTH_PER_UPGRADE
    return maxHealth