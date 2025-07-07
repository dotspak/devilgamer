extends Node
class_name BattleGrid

# holds the positions of all units currently spawned. Can hold a limit of 3 
# per side. Default entries are not used, and are designed to show how the array is setup.
# 0 = actors, 1 = enemies
var grid : Array[Array]
var deadActors : Array[Unit]

# clears the grid, then sets it according to the passed list of units
func setup(unitList : Array) -> void:
	# setup the grid array
	grid.clear()
	for i : int in range(2):
		grid.append([])
		for u : Unit in unitList[i]:
			grid[i].append(u)

# sets the entry at a specific spot
func add_entry(unit : Unit) -> void: 
	if grid[unit.is_enemy()].size() < 3:
		grid[unit.is_enemy()].append(unit)

func remove_unit(unit : Unit) -> void: grid[unit.is_enemy()].erase(unit)
func get_unit_idx(unit : Unit) -> int: return grid[unit.is_enemy()].find(unit)
func check_units_alive(side : int = 0) -> bool: return !grid[side].is_empty()

# gets the center x position of the enemies on the screen
func get_enemy_center() -> float:
	var size : int = 0
	var total : float = 0
	for u : Unit in grid[1]:
		total += u.model.global_position.x
		size += 1
	if size <= 0: size = 1
	return total / size

# returns an array of all units currently alive
func get_units() -> Array[Unit]:
	var units : Array[Unit]
	for i : int in range(2):
		for u : Unit in grid[i]:
			units.append(u)
	return units


