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
        health = val
        hpChanged.emit(health)

signal hpChanged(val : float)
signal mhpChanged(val : float)

func _ready(): reset_health()
func reset_health() -> void: health = maxHealth

func take_damage(amount : float, isTrueDmg : bool = false) -> float:
    # handle damage resistance
    if !isTrueDmg:
        var buffs : Array = Utils.get_all_components(owner, Buff)
        for b in Utils.filter_buffs_by_tag(buffs, Buff.BUFF_TAG.def): b.buff_value(amount)

    # take the final calculated damage, can't go below 1 damage ever
    health -= max(ceilf(amount), 1)
    return amount


func heal_damage(amount : float) -> float:    
    # handle heal buff resistance
    var buffs : Array = Utils.get_all_components(owner, Buff)
    for b in Utils.filter_buffs_by_tag(buffs, Buff.BUFF_TAG.heal): b.buff_value(amount)
    health = clamp(health + amount, 0, maxHealth * OVERHEALTH_RATIO)
    return amount


func create_def_buff(amount : float = 1.1, isMultiplier : bool = true, duration : float = 60, source : String = "ResBuff") -> void:
    var prevBuff : Buff = find_child(source)
    if prevBuff: prevBuff.reset_buff()
    else: add_child(Utils.create_buff(amount, isMultiplier, duration, source, Buff.BUFF_TAG.def))

func create_heal_buff(amount : float = 1.1, isMultiplier : bool = true, duration : float = 60, source : String = "ResBuff") -> void:
    var prevBuff : Buff = find_child(source)
    if prevBuff: prevBuff.reset_buff()
    else: add_child(Utils.create_buff(amount, isMultiplier, duration, source, Buff.BUFF_TAG.def))
