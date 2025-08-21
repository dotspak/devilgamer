# skill.gd --------------------------------------------
# holds all the data for a given action.
extends Resource
class_name Skill

enum DMG_TYPES {PHYS, MAG, TRUE}

@export_group("Info")
@export var name : String = "Ball"
@export_multiline var description : String = "Dummy description goes here!"

@export_group("Damage")
@export var dmgFormula : String = "10"
@export var selfTarget : bool = false
@export var castType : DMG_TYPES = DMG_TYPES.PHYS
@export var dmgType : DMG_TYPES = DMG_TYPES.PHYS
@export var variance : float = 3.0
@export var recoil : float = 0

@export_group("Cooldowns")
@export var cooldown : float = 1.0
@export var skillLock : float = 0.5

@export_group("Healing")
@export var isHeal : bool = false
@export var selfHeal : float = 0

@export_group("Rates")
@export var critRate : float = 0
@export var critDmg : float = 0
@export var drainRate : float = 0


func evaluate_formla(caster : Entity) -> float:
    var statTokens : Dictionary = {
        # core stats
        "MHP" : str(caster.stats.get_stat(StatComponent.STATS.MHP)),
        "ATK" : str(caster.stats.get_stat(StatComponent.STATS.ATK)),
        "MAG" : str(caster.stats.get_stat(StatComponent.STATS.MAG)),
        "DEF" : str(caster.stats.get_stat(StatComponent.STATS.DEF)),
        "MDF" : str(caster.stats.get_stat(StatComponent.STATS.MDF)),
        "LUC" : str(caster.stats.get_stat(StatComponent.STATS.LUC)),

        # rates
        "REGEN" : str(caster.stats.get_rate(StatComponent.RATES.REGEN)),
        "CRIT" : str(caster.stats.get_rate(StatComponent.RATES.CRIT)),
        "CRITDMG" : str(caster.stats.get_rate(StatComponent.RATES.CRITDMG)),
        "DRAIN" : str(caster.stats.get_rate(StatComponent.RATES.DRAIN)),
    }

    var formula : String = dmgFormula
    if formula == "": formula = statTokens["MAG"] if dmgType == DMG_TYPES.MAG else statTokens["ATK"]
    else:
        for t : String in statTokens.keys():
            formula = formula.replace(t, statTokens[t])
        

    var eval : Expression = Expression.new()
    var error : Error = eval.parse(formula, [])
    if error != OK:
        printerr("Failed to parse formula for ", caster.name, " : ", name)
        return 0
    
    var result : float = eval.execute()
    if eval.has_execute_failed():
        printerr("Failed to parse formula for ", caster.name, " : ", name)
        return 0

    return result


func calc_damage(caster : Entity) -> float:
    var DMG : float = evaluate_formla(caster)
    var finalVariance : Vector2 = calc_variance_with_luck(caster.stats.get_stat(StatComponent.STATS.LUC))
    return DMG + randf_range(finalVariance.x, finalVariance.y)


func calc_variance_with_luck(luck : float) -> Vector2:
    if variance == 0: return Vector2.ZERO

    var luckRatio : float = 1 - (luck / 20)
    var bottom : float = -clamp(roundf(variance * luckRatio), 0, variance)

    return Vector2(bottom, variance)
    