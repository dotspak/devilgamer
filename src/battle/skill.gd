# skill.gd --------------------------------------------
# holds all the data for a given action.
extends Resource
class_name Skill

enum DMG_TYPES {PHYS, MAG, TRUE}

@export_group("Info")
@export var name : String = "Ball"
@export_multiline var description : String = "Dummy description goes here!"

@export_group("Cooldowns")
@export var cooldown : float = 1.0
@export var moveLock : float = 0.5

@export_group("Damage")
@export var castType : DMG_TYPES = DMG_TYPES.PHYS
@export var dmgType : DMG_TYPES = DMG_TYPES.PHYS
@export var variance : float = 3.0
@export var baseDmg : float = 2.0
@export var recoil : float = 0

@export_group("Heal")
@export var isHeal : bool = false
@export var selfHeal : float = 0

@export_group("Rates")
@export var critRate : float = 0
@export var critDmg : float = 0
@export var drainRate : float = 0


func calc_damage(caster : Entity) -> float:
    var stat : StatComponent.STATS = \
        StatComponent.STATS.ATK if dmgType == DMG_TYPES.PHYS else \
        StatComponent.STATS.MAG if dmgType == DMG_TYPES.MAG else -1
    
    var statDmg : float 
    if stat >= 0: 
        statDmg = caster.stats.get_stat(stat)
    else: 
        statDmg = caster.stats.get_stat(StatComponent.STATS.ATK)\
        + caster.stats.get_stat(StatComponent.STATS.MAG)

    var finalVariance : Vector2 = calc_variance_with_luck(caster.stats.get_stat(StatComponent.STATS.LUC))
    return statDmg + baseDmg + randf_range(finalVariance.x, finalVariance.y)


func calc_variance_with_luck(luck : float) -> Vector2:
    if variance == 0: return Vector2.ZERO

    var luckRatio : float = 1 - (luck / 20)
    var bottom : float = -clamp(roundf(variance * luckRatio), 0, variance)

    return Vector2(bottom, variance)
    