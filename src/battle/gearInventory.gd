extends Node
class_name GearInventory

var slotIDX : int = 0 : 
	set(val):
		slotIDX = clamp(val, 0, max(get_gear_amount() - 1, 0))
		GameManager.battleBar.slotIDX = slotIDX


func _unhandled_input(_event: InputEvent) -> void:
	if GameManager.player.inputAllowed:
		if Input.is_action_just_pressed("skill_up"): slotIDX += 1
		elif Input.is_action_just_pressed("skill_down"): slotIDX -= 1
		else:
			if Input.is_action_just_pressed("skill_slot1"): slotIDX = 0
			elif Input.is_action_just_pressed("skill_slot2"): slotIDX = 1
			elif Input.is_action_just_pressed("skill_slot3"): slotIDX = 2
			elif Input.is_action_just_pressed("skill_slot4"): slotIDX = 3


func inventory_updated(_node : Node) -> void:
	if !_node is Gear: return
	if !GameManager.battleBar.is_node_ready():
		await GameManager.battleBar.ready

	var updatedInvetory : Array[Gear] = []
	for n : Node in get_gear():
		updatedInvetory.append(n)
	GameManager.battleBar.update_inventory(updatedInvetory)
	

func get_gear() -> Array: return get_children().filter(func(n): return n is Gear)
func get_gear_amount() -> int: return get_gear().size()
func get_selected_gear() -> Gear: return get_child(slotIDX)
