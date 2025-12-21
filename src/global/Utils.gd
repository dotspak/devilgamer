@icon("res://icons/gameConstants.svg")
extends Node
class_name Utils

# --------------------------------------------
# global constants
# --------------------------------------------
# elemental effects
const RESIST_MOD : float = 0.7
const ELEM_BOOST_MOD : float = 1.5

# visuals
const ELEVATOR_FADE_COLOR : Color = Color.NAVY_BLUE

# --------------------------------------------
# global helper functions
# --------------------------------------------
# finds the first node of the given type from the passed node
static func get_component(node : Node, type : GDScript) -> Node:
    if node.get_script() == type: return node
    for n in node.get_children(true):
        if n.get_script() == type:
            print("Component found: ", n)
            return n
        
    printerr("No matching component found.")
    return null


# finds all nodes of a given type from the passed node
static func get_all_components(node : Node, type : GDScript) -> Array[Node]:
    var components : Array[Node] = []
    if node.get_script() == type: components.append(node)
    print(node.get_children(true))
    for n in node.get_children(true):
        if n.get_script() == type:
            components.append(n)
    return components


# creates a buff object from the given parameters
# amount - the amount the buff provides
# isMultiplier - determines whether the buff should be read as a percentage or flat value
# duration - the length of the buff, in seconds
# source - where the buff came from, prevents stacking buffs from one source
# tag - the type of buff it is
static func create_buff(amount : float = 1.1, isMultiplier : bool = true, duration : float = 60, 
    source : String = "Buff", tag : Buff.BUFF_TAG = Buff.BUFF_TAG.atk) -> Buff:
        var buff = Buff.new(amount, isMultiplier, duration)
        buff.tag = tag
        buff.name = source
        return buff


# filters an array of buffs based on the passed buff tag
static func filter_buffs_by_tag(buffs : Array, tag : Buff.BUFF_TAG) -> Array[Buff]:
    var finalArray : Array[Buff] = []
    print("buffs before: ", buffs)
    for b in buffs:
        if b is Buff:
            if b.tag == tag:
                finalArray.append(b)
    print("remaining buffs: ", finalArray)
    return finalArray
