@icon("res://icons/attackComponent.png")
extends Node
class_name AttackComponent

@export var attack : float = 5

func get_attack() -> float: 
    var final : float = attack
    var buffs : Array = Utils.get_all_components(owner, Buff)
    for b in Utils.filter_buffs_by_tag(buffs, Buff.BUFF_TAG.def): final = b.buff_value(final)
    return final

func create_attack_buff(amount : float = 1.1, isMultiplier : bool = true, duration : float = 60, source : String = "AtkBuff") -> void:
    var prevBuff : Buff = find_child(source)
    if prevBuff: prevBuff.reset_buff()
    else: add_child(Utils.create_buff(amount, isMultiplier, duration, source, Buff.BUFF_TAG.atk))