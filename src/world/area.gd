@icon("res://icons/areaIcon.png")
extends Resource
class_name Area

const TRANSITION_ROOM : PackedScene = preload("res://scenes/areaTransitionRoom.tscn")

enum AREA_IDS {bath, freeze, abyss, lab, heaven, hub, border}
enum SPECIAL_ID {none = -1, elevator = -2}

@export_group("Area Info")
@export var ID : AREA_IDS
@export var areaName : String = "Area"
@export var areaDescription : String = "dummy description"

@export_group("Details")
@export_file_path var enviroPath : String
@export var environment : Environment
@export var bgm : AudioStream

@export_group("Room Pools")
@export var door : PackedScene
@export var roomPool : Array[RoomDef]
@export var requiredDeadEnds : Array[RoomDef]
@export var deadendPool : Array[RoomDef]

# creates an area definition file for the game to read and place rooms accordingly
func generate_area_def() -> AreaDef:
	var def : AreaDef = AreaDef.new()
	def.areaName = areaName
	def.areaDescription = areaDescription
	def.doorScene = door
	def.worldEnvironment = environment
	def.bgm = bgm
	def.ID = ID
	
	if enviroPath: def.areaEnvionment = load(enviroPath)

	var remRooms : Array[RoomDef] = roomPool.duplicate(true)
	var roomDefs : Array[RoomDef] = []

	# generate the first room
	var initDef : RoomDef = get_rand_room(remRooms)
	initDef.connectedExits = {}
	initDef.connectExitPartners = {}
	roomDefs.append(initDef)

	var openExits : Array[Dictionary] = []
	for exit : String in initDef.exits:
		openExits.append({"IDX" : 0, "EXIT" : exit})

	# generate remaining rooms
	while !remRooms.is_empty() && !openExits.is_empty():
		var nextDef : RoomDef = get_rand_room(remRooms)
		nextDef.connectedExits = {}
		nextDef.connectExitPartners = {}

		var nextIDX : int = roomDefs.size()
		roomDefs.append(nextDef)

		# connect an open exit to a room
		var exitData : Dictionary = openExits.pop_back()
		var prevRoomIDX : int = exitData.IDX
		var prevRoomExit : String = exitData.EXIT

		var nextExit : String = nextDef.exits.pick_random()
		nextDef.connectedExits[nextExit] = prevRoomIDX
		nextDef.connectExitPartners[nextExit] = prevRoomExit

		var prevDef : RoomDef = roomDefs[prevRoomIDX]
		prevDef.connectedExits[prevRoomExit] = nextIDX
		prevDef.connectExitPartners[prevRoomExit] = nextExit

		roomDefs[prevRoomIDX].connectedExits[prevRoomExit] = nextIDX

		# add remaining exits to open
		for exit in nextDef.exits:
			if exit != nextExit:
				openExits.append({"IDX" : nextIDX, "EXIT" : exit})

	fill_dead_ends(openExits, roomDefs, requiredDeadEnds)
	def.roomDefintions = roomDefs
	print("finished generating def for area: ", areaName)
	return def


# places dead ends at any remaining open exits 
func fill_dead_ends(openExits : Array[Dictionary], roomDefs : Array[RoomDef], required : Array[RoomDef]) -> void:
	# place required dead ends first if there are any
	# (note: this logic will eventually be scrapped, this is more for testing)
	if required:
		required = required.duplicate(true)

		# place required dead ends first
		while !required.is_empty() && !openExits.is_empty():
			var exitData : Dictionary = openExits.pop_back()
			var roomIDX : int = exitData.IDX
			var exit : String = exitData.EXIT

			var deadDef : RoomDef = required.pop_back()
			var deadEndCopy : RoomDef = deadDef.duplicate(true)
			if deadEndCopy.exits.is_empty():
				deadEndCopy.exits = deadEndCopy.get_exit_names()
			
			deadEndCopy.connectedExits = {deadEndCopy.exits[0] : roomIDX}
			roomDefs[roomIDX].connectedExits[exit] = roomDefs.size()
			roomDefs[roomIDX].connectExitPartners[exit] = deadEndCopy.exits[0]
			roomDefs.append(deadEndCopy)

	# fill remaining exits with dead ends
	while !openExits.is_empty():
		var exitData : Dictionary = openExits.pop_back()
		var roomIDX : int = exitData.IDX
		var exit : String = exitData.EXIT
		
		var deadDef : RoomDef = deadendPool.pick_random()
		var deadEndCopy : RoomDef = deadDef.duplicate(true)
		if deadEndCopy.exits.is_empty():
			deadEndCopy.exits = deadEndCopy.get_exit_names()
		
		deadEndCopy.connectedExits = {deadEndCopy.exits[0] : roomIDX}
		roomDefs[roomIDX].connectedExits[exit] = roomDefs.size()
		roomDefs[roomIDX].connectExitPartners[exit] = deadEndCopy.exits[0]
		roomDefs.append(deadEndCopy)


# returns a random room from the current pool of remaining rooms, then erases it from the pool
func get_rand_room(pool : Array[RoomDef]) -> RoomDef:
	var room : RoomDef = pool.pick_random()
	pool.erase(room)
	room = room.duplicate(true)
	if room.exits.is_empty(): room.exits = room.get_exit_names()
	return room


# gets the exit names of the passed room scene
func get_exit_names(scene : PackedScene) -> Array[String]:
	var temp : RoomInstance = scene.instantiate()
	return temp.get_exit_names()