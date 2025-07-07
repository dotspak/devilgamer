@icon("res://icons/roomDefIcon.png")
extends Resource
class_name RoomDef

@export var scene : PackedScene :
	set(val):
		scene = val
		exits = get_exit_names()

@export_group("Room Info")
@export var roomName : String = "room"
@export_multiline var description : String = "A room"

@export_group("Room Data")
@export var chests : Array[String]
@export var npcs : Array[String]
@export var exits : Array[String]

var connectedExits : Dictionary = {}
var connectExitPartners : Dictionary = {}

# for area transitions
var targetArea : String = ""
var targetExit : String = ""

var isTerminal : bool = false

func get_exit_names() -> Array[String]:
	var temp : RoomInstance = scene.instantiate()
	return temp.get_exit_names()
