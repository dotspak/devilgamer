@icon("res://icons/battleData.png")
extends Node
class_name BattleFormation

# ----------------------------------------------------------------------
# Actors
# ----------------------------------------------------------------------
var actors : Array[Actor]
var deadActors : Array[Actor]

func add_actor(actor : Actor) -> int: 
	actors.append(actor)
	return actors.find(actor)

func remove_actor(actor : Actor) -> int: 
	var idx : int = actors.find(actor)
	if idx >= 0: actors.erase(actor)
	return idx

func get_actors(checkDead : bool = false) -> Array[Actor]:
	var arr : Array[Actor]
	for a : Actor in actors:
		if checkDead || a.phase != Unit.Phase.DEAD:
			arr.append(a)
	return arr

func get_actor(idx : int = 0) -> Actor: return actors[idx] if idx < actors.size() else null
func get_actor_idx(actor : Actor) -> int: return actors.find(actor)
func are_actors_dead() -> bool: return get_actors().is_empty()
func get_next_actor_idx(actor : Actor, dir : int = 1) -> int:
	var IDX : int = get_actor_idx(actor)
	if IDX + dir < actors.size() && IDX + dir >= 0: IDX += dir
	return IDX

func add_actor_to_dead(actor : Actor) -> void:
	deadActors.resize(3)
	deadActors[get_actor_idx(actor)] = actor
	remove_actor(actor)

func revive_actor(actor : Actor) -> void:
	actors.resize(3)
	actors.insert(deadActors.find(actor), actor)
	deadActors.erase(actor)

# ----------------------------------------------------------------------
# Enemies
# ----------------------------------------------------------------------
var enemies : Array[Enemy]

# appends an enemy, then returns their idx
func add_enemy(enemy : Enemy) -> int: 
	enemies.append(enemy)
	return enemies.find(enemy)

# removes and enemy, returns idx
func remove_enemy(enemy : Enemy) -> int: 
	var idx : int = enemies.find(enemy)
	if idx >= 0: enemies.erase(enemy)
	return idx

func get_enemies() -> Array[Enemy]:
	var arr : Array[Enemy]
	for e : Enemy in enemies:
		if e.phase != Unit.Phase.DEAD:
			arr.append(e)
	return arr

func get_enemy(idx : int = 0) -> Enemy: return enemies[idx] if idx < enemies.size() else null
func get_enemy_idx(enemy : Enemy) -> int: return enemies.find(enemy)
func are_enemies_dead() -> bool: return get_enemies().is_empty()

# ----------------------------------------------------------------------
# General
# ----------------------------------------------------------------------
func add_unit(unit : Unit) -> void:
	if unit is Actor: add_actor(unit)
	elif unit is Enemy: add_enemy(unit)

func remove_unit(unit : Unit) -> void:
	if unit is Actor: remove_actor(unit)
	elif unit is Enemy: remove_enemy(unit)

func setup(units : Array[Array]) -> void:
	for i : int in units.size():
		for u : Unit in units[i]:
			add_unit(u)

func get_units() -> Array[Unit]:
	var units : Array[Unit]
	units.append_array(actors)
	units.append_array(enemies)
	return units
