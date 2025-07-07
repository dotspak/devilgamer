extends Resource
class_name Element

enum Elements {NONE, PHYS, FIRE, AQUA, ELECTRIC, HOLY, VILE, RAD, SUPPORT, HINDER, HEAL}

@export var element : Elements = Elements.NONE
@export var reaction : Elements = Elements.NONE

const R : float = 2 # damage multiplier for reactions

# first element = attack, second element = defense
static var reactionTable : Array[Array]= [
	[1,1,1,1,1,1,1,1], # none
	[1,1,1,1,1,1,1,1], # phys
	[1,1,1,1,R,1,1,1], # fire
	[1,1,R,1,1,1,1,1], # aqua
	[1,1,1,R,1,1,1,1], # electric
	[1,1,1,1,1,1,R,1], # holy
	[1,1,1,1,1,R,1,1], # vile
	[1,1,1,1,1,1,1,1], # radi
]

static func reaction_ref(attacking : Elements, defending : Elements) -> float:
	return reactionTable[attacking][defending] if is_elemental(attacking) && is_elemental(defending) else 1

static func is_elemental(e : Elements) -> bool: return e >= Elements.FIRE && e <= Elements.RAD
