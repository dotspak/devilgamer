@icon("res://icons/healthComoponent.png")
extends Node
class_name HealthComponent

const OVERHEALTH_RATIO : float = 1.25

@export var maxHealth : float = 100
var health : float = 1 :
    set(val):
        health = val
        HPChanged.emit(health)

signal HPChanged(val : float)
signal HPZero

func _init(_health : float):
    maxHealth = _health
    reset_health()

func _ready(): reset_health()
func reset_health() -> void: health = maxHealth


func take_damage(amount : float) -> void:
    # handle damage resistance
    var buffs : Array = Utils.get_all_components(owner, Buff)
    for b in Utils.filter_buffs_by_tag(buffs, Buff.BUFF_TAG.def): b.buff_value(amount)

    # take the final calculated damage, can't go below 1 damage ever
    health -= max(ceilf(amount), 1)
    if health <= maxHealth: HPZero.emit()


func heal_damage(amount : float) -> void:    
    # handle heal buff resistance
    var buffs : Array = Utils.get_all_components(owner, Buff)
    for b in Utils.filter_buffs_by_tag(buffs, Buff.BUFF_TAG.heal): b.buff_value(amount)
    health = clamp(health + amount, 0, maxHealth * OVERHEALTH_RATIO)


func create_def_buff(amount : float = 1.1, isMultiplier : bool = true, duration : float = 60, source : String = "ResBuff") -> void:
    var prevBuff : Buff = find_child(source)
    if prevBuff: prevBuff.reset_buff()
    else: add_child(Utils.create_buff(amount, isMultiplier, duration, source, Buff.BUFF_TAG.def))

func create_heal_buff(amount : float = 1.1, isMultiplier : bool = true, duration : float = 60, source : String = "ResBuff") -> void:
    var prevBuff : Buff = find_child(source)
    if prevBuff: prevBuff.reset_buff()
    else: add_child(Utils.create_buff(amount, isMultiplier, duration, source, Buff.BUFF_TAG.def))
