@icon("res://icons/gearIcon.png")
extends Node
class_name Gear

enum GEAR_MODE {ALPHA, OMEGA}
@export var gearName : String = ""
@export_multiline var description : String = ""
@export var sprite : Texture
@export var mode : GEAR_MODE = GEAR_MODE.ALPHA
@export var action_a : PackedScene
@export var action_b : PackedScene

## check this if you are using gear to simply store an action, ie for an enemy
## playable entities should never have gear with this checked.
## This is used for if you don't want to display any info about the gear except
## the action/skill associated with it.
@export var isPlaceholder : bool = false

var statComponent : StatComponent
var passives : Array[Passive]
var entity : Entity
@export var stacks : int = 0 :
    set(val):
        stacks = val
        stacksChanged.emit(stacks)

signal stacksChanged(stacks : int)

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




# getters --------------------------------
func get_action_scene() -> PackedScene: return action_a if mode == GEAR_MODE.ALPHA else action_b
func get_sprite() -> Texture: return sprite


func get_skill() -> Skill:
    var inst : Action = instance_action()
    return inst.skill if inst else null


func get_skill_desc() -> String:
    var inst : Action = instance_action()
    return inst.skill.description if inst else ""


func get_info() -> Dictionary:
    var info : Dictionary = {"NAME" : "", "DESCRIPTION" : ""}
    if !isPlaceholder:
        info.NAME = gearName
        info.DESCRIPTION = description
    else:
        var action : Action = instance_action()
        if action:
            info.NAME = action.skill.name
            info.DESCRIPTION = action.skill.description
    return info

