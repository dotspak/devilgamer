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
    for n in node.get_children(true):
        if n.get_script() == type:
            components.append(n)
    return components