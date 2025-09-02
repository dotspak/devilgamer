@icon("res://icons/roomIcon.png")
@tool
extends Node3D
class_name RoomInstance

@export_tool_button("Generate RoomDef File") var genRoomDefButton = func() -> void:
	var def : RoomDef = generate_room_def()
	if def: save_room_def(def)

@export_group("Room Properties")
@export var roomName : String = "room"
@export_multiline var description : String = "A room"
@export var tilemap : RoomTileMap

@export_group("Room Collections")
@export var chests : Array[Node3D]
@export var npcs : Array[Node3D]
@export var exits : Array[Node3D]

var definition : RoomDef
var connectedDoors : Array[DoorInstance]

# called when entering the room
func enter_room() -> void:
	print("entering room ", roomName)
	show()
	GameManager.currentRoom = self
	collision_disable_enable(self, false)


# called when exiting the room
func exit_room() -> void:
	print("exiting room ", roomName)
	hide()
	collision_disable_enable(self, true)
	

func collision_disable_enable(node : Node3D, shouldDisable : bool) -> void:
	for n : Node in node.get_children():
		if n is CollisionShape3D: n.set_deferred("disabled", shouldDisable)
		elif n.get_child_count() > 0: collision_disable_enable(n, shouldDisable)


# checks if the room doesn't have any meaningful content
func is_filler() -> bool: return !chests && !npcs


func get_exit(exitName : String) -> Node3D:
	for exit in exits:
		if exit.name == exitName:
			return exit
	return null


func get_exit_names() -> Array[String]:
	var names : Array[String] = []
	for e in exits: names.append(e.name)
	return names


func get_chest_names() -> Array[String]:
	var names : Array[String] = []
	for c in chests: names.append(c.name)
	return names


func get_NPC_names() -> Array[String]:
	var names : Array[String] = []
	for n in npcs: names.append(n.name)
	return names


# generates a room defintion file for the scene
func generate_room_def() -> RoomDef:
	var def : RoomDef = RoomDef.new()
	if self is RoomToArea: 
		def = RoomToAreaDef.new()
		def.toArea = self.toArea
	def.roomName = roomName
	def.description = description
	def.chests = get_chest_names()
	def.exits = get_exit_names()
	def.scene = load(scene_file_path)
	return def


# saves the room a room definition file to the filepath
func save_room_def(def : RoomDef) -> void:
	if !scene_file_path:
		printerr("Scene must be saved before generating RoomDef file.")
		return

	var defPath : String = scene_file_path.get_basename() + ".tres"
	var err := ResourceSaver.save(def, defPath)
	if err == OK: print("RoomDef saved to ", defPath)
	else: printerr("Failed to save RoomDef: ", err)