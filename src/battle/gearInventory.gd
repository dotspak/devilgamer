extends Node
class_name GearInventory

func get_actions() -> Array[Action]:
    var actions : Array[Action]
    for n : Gear in get_children():
        actions.append(n.instance_action())

    return actions

