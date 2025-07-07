extends Resource
class_name CharSheet

const FAKE_LVL : int = 3

@export_group("info")
@export var model : PackedScene = load("res://assets/battleSprites/puppets/test/heca.tscn")
@export var name : String = "gumbo"
@export_multiline var description : String

@export_group("Statistical")
## the base stats of the unit
@export var stats : Dictionary = { 
    "VIG" : 3,
    "STR" : 3,
    "MAG" : 3,
    "DEF" : 3,
    "AGI" : 3
}
@export var baseElement : Element.Elements ## the element the unit will revert to after a reaction

@export_group("Skills + Equipment")
@export var skillList : Array[Skill] = []

var MHP : float = 0
var HP : float = 0

# determines the unit's based on their stats
func calc_mhp() -> float:
  MHP =  ceili(
  5 * (FAKE_LVL *
  sqrt(stats["VIG"] / 5) +  # square root of HP / 5
  (stats["VIG"] + FAKE_LVL))) # HP + lvl
  return MHP
