# actionMod.gd ---------------------------------------------
# This is simply a base class for all actionMods to inherit from.
# Should never be created, only referenced. Should always be a child of
# an action.
@icon("res://icons/battleData.png")
extends Node
class_name ActionMod

var action : Action

func set_action(_action : Action) -> void: action = _action