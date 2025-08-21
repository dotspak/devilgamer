# actionMod.gd ---------------------------------------------
# This is simply a base class for all actionMods to inherit from.
# Should never be created, only referenced. Should always be a child of
# an action.
@icon("res://icons/battleData.png")
extends Node
class_name ActionMod

var action : Action

signal actionSet

func set_action(_action : Action) -> void:
    if _action && !_action.spawned: await _action.actionSpawned
    action = _action
    actionSet.emit()