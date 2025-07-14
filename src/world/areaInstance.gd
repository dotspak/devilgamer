@icon("res://icons/areaIcon.png")
extends Node3D
class_name AreaInstance

const AREA_FADE_TIME : float = 1.5

@export var defintion : AreaDef
@export var generatedRooms : Array[RoomInstance]
@export var areaTransitionRooms : Dictionary[String, RoomToArea]

var bgmPlayer : AudioStreamPlayer = AudioStreamPlayer.new()

func _init(def : AreaDef): defintion = def
func area_intro(color : Color = Color.WHITE) -> void:
	add_child(bgmPlayer)
	await get_tree().create_timer(1.0).timeout
	await GameManager.fadein_screen(AREA_FADE_TIME, color, GameManager.fadeTargets.AREA)

	GameManager.show_battle_ui()
	GameManager.animate_intro_text(defintion.areaName, defintion.areaDescription)
	CameraManager.enable_main_cam()

	# play the bgm
	await get_tree().create_timer(1).timeout
	if defintion.bgm: AudioManager.play_bgm(defintion.bgm, 1, 1, AREA_FADE_TIME)


func transition_to_area(area : String, playerPos : Vector3) -> void:
	print("transitioning to area: ", area)
	GameManager.player.move_to_position(playerPos)
	GameManager.hide_battle_ui()
	AudioManager.fade_bgm(AREA_FADE_TIME)
	await GameManager.fadeout_screen(AREA_FADE_TIME, Color.WHITE, GameManager.fadeTargets.AREA)
	GameManager.load_area(area, defintion.areaName)


func spawn_rooms_from_def() -> void:
	defintion.visualize_area_def()

	# instantiate all rooms
	for def : RoomDef in defintion.roomDefintions:
		var instance : RoomInstance = def.scene.instantiate()
		add_child(instance)
		instance.definition = def
		instance.name = str(generatedRooms.size()) + " : " + instance.roomName
		instance.exit_room()

		# setup transition rooms
		if instance is RoomToArea: 
			areaTransitionRooms[instance.toArea] = instance
			instance.areaTransitionEntered.connect(transition_to_area)
			instance.toArea = def.toArea
		
		generatedRooms.append(instance)

	# place first room at origin
	generatedRooms[0].global_transform.origin = Vector3.ZERO
	
	# connect rooms together
	for i : int in defintion.roomDefintions.size():
		var thisRoom : RoomInstance = generatedRooms[i]

		for exit in thisRoom.definition.connectedExits.keys():
			var connectedIDX = thisRoom.definition.connectedExits[exit]
			if typeof(connectedIDX) != TYPE_INT: continue

			var otherRoom : RoomInstance = generatedRooms[connectedIDX]

			print("exits of the current rooms: \n",
				thisRoom.definition.roomName, " : ",thisRoom.definition.connectExitPartners, "\n", 
				otherRoom.definition.roomName, " : ", otherRoom.definition.connectExitPartners)
			
			# skip duplicate connections
			if i > connectedIDX: continue
	
			# create and connect a door between the two
			var door : DoorInstance = defintion.doorScene.instantiate()
			add_child(door)

			var thisExit : Node3D = thisRoom.get_exit(exit)
			var otherExitName : String = thisRoom.definition.connectExitPartners[exit]
			var otherExit : Node3D = otherRoom.get_exit(otherExitName)
			
			connect_room_to_door(thisRoom, thisExit, door, true)
			connect_door_to_room(door, false, otherRoom, otherExit)
	
	# spawn the area environment
	var worldEnv : WorldEnvironment = WorldEnvironment.new()
	worldEnv.environment = defintion.worldEnvironment
	add_child(worldEnv)


func connect_room_to_door(room : RoomInstance, roomExit : Node3D, door : DoorInstance, useEntryA : bool):
	var doorEntry : Node3D = door.entryA if !useEntryA else door.entryB
	var roomMarkerGlobal : Transform3D = roomExit.global_transform
	var doorMakerLocal : Transform3D = doorEntry.transform
	var doorGlobalTransform : Transform3D = roomMarkerGlobal * doorMakerLocal.affine_inverse()
	door.global_transform = doorGlobalTransform

	# connect to the correct entry
	if useEntryA: door.roomA = room
	else: door.roomB = room
	room.connectedDoors.append(door)


func connect_door_to_room(door : DoorInstance, useEntryA : bool, room : RoomInstance, roomExit : Node3D):
	var doorEntry : Node3D = door.entryA if !useEntryA else door.entryB
	var doorMarkerGlobal : Transform3D = doorEntry.global_transform
	var roomMarkerLocal : Transform3D = roomExit.transform
	var roomGlobalTransform : Transform3D = doorMarkerGlobal * roomMarkerLocal.affine_inverse()
	room.global_transform = roomGlobalTransform

	# connect to the correct entry
	if useEntryA: door.roomA = room
	else: door.roomB = room
	room.connectedDoors.append(door)


# used for spawning the player correctly
func find_entry_room(fromArea : String) -> RoomToArea: return areaTransitionRooms[fromArea]
func get_player_spawn(areaRoom : RoomToArea) -> Vector3: return areaRoom.spawnPoint.global_position