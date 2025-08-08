@icon("res://icons/gearIcon.png")
extends Node
class_name Gear

enum GEAR_MODE {ALPHA, OMEGA}
@export var gearName : String = ""
@export_multiline var description : String = ""
@export var model : Node3D
@export var action_a : PackedScene
@export var action_b : PackedScene

var mode : GEAR_MODE = GEAR_MODE.ALPHA
var statComponent : StatComponent
var passives : Array[Passive]
var entity : Entity

func _ready():
    if find_entity(get_parent()):
        for n : Node in get_children():
            if n is Passive: 
                passives.append(n)
                n.setup(entity)
                
            if n is StatComponent: 
                statComponent = n


func find_entity(parent : Node) -> bool:
    if parent is Entity: entity = parent
    elif parent == get_tree().root: return false
    else: find_entity(parent.get_parent())
    return true
    

func instance_action() -> Action:
    var inst : Node = action_a.instantiate() if mode == GEAR_MODE.ALPHA else action_b.instantiate()
    return inst if inst is Action else null


func get_model() -> Node3D: return model.duplicate()