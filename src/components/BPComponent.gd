# handles all bp logic for the player, shouldn't be used on any other entities
@icon("res://icons/bpComponent.png")
extends Node
class_name BPComponent

const BP_PER_UPGRADE : int = 25

@export var bpUpgrades : int = 2 :
    set(val):
        bpUpgrades = val
        calc_max_bp()
        reset_bp()

var BP : float = 100 :
    set(val):
        BP = clamp(val, 0, maxBP)
        bpChanged.emit(BP)

var maxBP : float = 100 :
    set(val):
        maxBP = val
        maxBpChanged.emit(maxBP)

signal bpChanged(val : float)
signal maxBpChanged(val : float)

func _ready():
    calc_max_bp()
    reset_bp()

func calc_max_bp() -> float:
    maxBP = bpUpgrades * BP_PER_UPGRADE
    return maxBP

func reset_bp() -> void: BP = maxBP