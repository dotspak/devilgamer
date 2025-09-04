@icon("res://icons/flagIcon.svg")
extends Node

var playerName : String = ""

# General game flag control ----------------------------------------
var FLAGS : Dictionary[String, Variant] = {
	"testFlag" : true,
	"testNumberFlag" : 0
}

func check_flag(flag : String):
	var result = false if !FLAGS.has(flag) else FLAGS[flag]
	print(flag, " : ", str(result))
	return result


func set_flag(flag : String, val : Variant) -> void:
	print(flag, " set to : ", str(val)) 
	FLAGS[flag] = val


# Key item control ----------------------------------------
var KEY_ITEMS : Dictionary[String, Dictionary] = {}

func check_keyItem(keyItem : String) -> Dictionary:
	if !KEY_ITEMS.has(keyItem): 
		print(keyItem + " : not obtained")
		return {}
	else: 
		print(keyItem + " : found")
		return KEY_ITEMS[keyItem]


# Elevator control ----------------------------------------
var ELEVATORS : Dictionary[String, bool] = {}

# note: if there were a situation where an elevator could become deactivated,
# this function handles this.
func check_elevator(elevatorID : String) -> bool:
	var result : bool = ELEVATORS.has(elevatorID) && ELEVATORS[elevatorID]
	print("elevator " + elevatorID + " : " + str(result))
	return result


func unlock_elevator(elevatorID : String) -> void:
	print(elevatorID + " : is now unlocked")
	ELEVATORS[elevatorID] = true


func lock_elevator(elevatorID : String) -> void:
	print(elevatorID + " : is now locked")
	ELEVATORS[elevatorID] = false