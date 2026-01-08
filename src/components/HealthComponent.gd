@icon("res://icons/healthComoponent.png")
extends Node
class_name HealthComponent

const OVERHEALTH_RATIO : float = 1.25

@export var maxHealth : float = 100 :
	set(val):
		maxHealth = val
		mhpChanged.emit(maxHealth)

var health : float = 1 :
	set(val):
		health = min(val, maxHealth * OVERHEALTH_RATIO)
		hpChanged.emit(health)



signal hpChanged(val : float)
signal mhpChanged(val : float)

func _ready(): reset_health()
func reset_health() -> void: health = maxHealth

func take_damage(amount : float, isTrueDmg : bool = false) -> float:
	# handle damage resistance
	if !isTrueDmg: amount = owner.apply_damage_mod(amount)

	# take the final calculated damage, can't go below 1 damage ever
	amount = max(ceilf(amount), 1)
	health -= amount
	return amount


func heal_damage(amount : float) -> float:    
	# handle heal buff resistance
	var healBuffs : Array = Utils.get_all_components(owner, BonusHealComponent)
	for bh : BonusHealComponent in healBuffs:
		if amount <= 0: continue
		if bh.isMultiplier: amount *= bh.amount
		else: amount += bh.amount
	health = clamp(health + amount, 0, maxHealth * OVERHEALTH_RATIO)
	return amount


