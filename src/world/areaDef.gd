@icon("res://icons/areaIcon.png")
extends Resource
class_name AreaDef

var areaName : String = "Area"
var worldEnvironment : Environment
var bgm : AudioStream
var areaDescription : String = "dummy description"
var roomDefintions : Array[RoomDef]
var doorScene : PackedScene

func visualize_area_def(def: AreaDef = self) -> void:
	print("=== Area Definition: %s ===" % areaName)
	print("Description: %s" % def.areaDescription)
	print("Total Rooms: %d" % def.roomDefintions.size())
	print("-----------------------------------")

	for i in def.roomDefintions.size():
		var room_def = def.roomDefintions[i]
		print("Room %d" % i, " ", room_def.roomName)
		print(" - Scene: ", room_def.scene.resource_path)
		print(" - Exits: ", room_def.exits)
		print(" - Connected Exits:")
		
		for exit_name in room_def.connectedExits:
			var target_index = room_def.connectedExits[exit_name]
			print("     • '%s' → Room %d" % [exit_name, target_index], " ", def.roomDefintions[target_index].roomName)

		if room_def.isTerminal:
			print(" - TERMINAL ROOM")
		
	print("\n")
	for i in def.roomDefintions.size():
		var node = def.roomDefintions[i]
		for exit_name in node.connectedExits:
			var j = node.connectedExits[exit_name]
			print("Room %d --[%s]--> Room %d" % [i, exit_name, j])

	print("=== End of Area ===")
