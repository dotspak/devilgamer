extends HealthComponent
class_name PlayerHealthComponent

const HEALTH_PER_UPGRADE : float = 25

@export var healthUpgrades : int = 3 :
    set(val):
        healthUpgrades = val
        maxHealth = healthUpgrades * HEALTH_PER_UPGRADE
        reset_health()