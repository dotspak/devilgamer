extends Node
class_name StatComponent

const EVA_REDUCTION : float = 0.5

# dictionary listing base stats of the entity
enum STATS{MHP, ATK, MAG, DEF, MDF, LUC}
@export var stats : Dictionary[STATS, float] = {
	STATS.MHP : 50,
	STATS.ATK : 3,
	STATS.MAG : 3,
	STATS.DEF : 3,
	STATS.MDF : 3,
	STATS.LUC : 3
}

# dictionary listing base rates of the entity
enum RATES{REGEN, CRT, CDMG, EVA}
@export var rates : Dictionary[RATES, float] = {
	RATES.REGEN : 1.0, ## hp/sec
	RATES.CRT : 0.01, ## crit %
	RATES.EVA : 0, ## evasion %
	RATES.CDMG : 1.2 ## crit dmg (dmg * CDMG)
}

var entity : Entity
var HP : float = stats[STATS.MHP] :
	set(val):
		HP = val
		hpChanged.emit(HP)

signal hpChanged(val : float)

# setters/getters -----------------------------------------------------
func get_stat(stat : STATS) -> float: return stats[stat]
func get_rate(rate : RATES) -> float : return rates[rate]

func set_stat(stat : STATS, val : float) -> void:
	if stat == STATS.MHP: set_MHP(val)
	else: stats[stat] = val

func set_rate(rate : RATES, val : float) -> void: rates[rate] = val

func set_MHP(val : float) -> void: stats[STATS.MHP] = val # TODO, change with proper HP scaling logic
	
func calc_crit_chance() -> float: return get_rate(RATES.CRT) * get_stat(STATS.LUC)
func calc_eva_chance() -> float: return get_rate(RATES.EVA) * get_stat(STATS.LUC) * EVA_REDUCTION