extends Control
class_name BattleActions

const ICON_IDX : int = 0
const STACK_IDX : int = 2
const LABEL_HEADER : String = "[bgcolor=000]> "
const STACK_HEADER : String = "[outline_size=4][outline_color=000][color=5ff]"

@onready var gearBox : HBoxContainer = %gear
@onready var selectedLabel : RichTextLabel = %selectedLabel

var gear : Array[Gear] = []
var slotIDX : int = -1 :
	set(val):
		if gear.is_empty() || slotIDX == val: return

		var prevIDX : int = slotIDX
		slotIDX = val

		if get_parent().visible: AudioManager.play_ui_sfx("cursor")
		animate_deselect(gearBox.get_child(prevIDX))
		aninmate_select(gearBox.get_child(slotIDX))
		
		if selectedLabel:
			var text : String = gear[slotIDX].gearName if get_gear_amount() > 0 else "NULL"
			selectedLabel.text = LABEL_HEADER + text		


func update_inventory(inventory : Array[Gear]) -> void:
	if inventory.is_empty() || gear == inventory : return
	
	slotIDX = 0
	gear = inventory
	gear.resize(4)
	
	for i : int in gear.size():
		var slot : PanelContainer = gearBox.get_child(i)
		var styleBox : StyleBoxFlat = slot.get_theme_stylebox("panel")
		styleBox.border_width_left = 0
		styleBox.border_width_right = 0
		
		if gear[i]:
			var g : Gear = gear[i]
			slot.get_child(ICON_IDX).texture = g.get_sprite()
			stacks_changed(g.stacks, g)
			
			if g.stacksChanged.is_connected(stacks_changed):
				g.stacksChanged.disconnect(stacks_changed)
			g.stacksChanged.connect(stacks_changed.bind(g))
		
		else:
			slot.get_child(ICON_IDX).texture = null
			slot.get_child(STACK_IDX).text = ""
			slot.modulate.a = 0.5

	


func stacks_changed(stacks : int, g : Gear) -> void:
	var idx : int = gear.find(g)
	if idx >= 0:
		var finalNum : String = str(stacks) if stacks > 0 else ""
		gearBox.get_child(idx).get_child(STACK_IDX).text = STACK_HEADER + str(finalNum)


func get_gear_amount() -> int:
	var total : int = 0
	for n in gear: if n: total += 1
	return total


func aninmate_select(slot : PanelContainer) -> void:
	var duration : float = 0.1
	var box : StyleBoxFlat = slot.get_theme_stylebox("panel")
	var TW : Tween = create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	TW.tween_property(box, "border_width_left", 4, duration)
	TW.tween_property(box, "border_width_right", 4, duration)

	var deltaSize : float = 1.2
	var TW2 : Tween = create_tween().set_trans(Tween.TRANS_SINE)
	slot.pivot_offset = Vector2(24, 24)
	TW2.tween_property(slot, "scale", Vector2.ONE * deltaSize, duration * 0.5)
	TW2.tween_property(slot, "scale", Vector2.ONE, duration * 0.5)


func animate_deselect(slot : PanelContainer) -> void:
	var duration : float = 0.1
	var box : StyleBoxFlat = slot.get_theme_stylebox("panel")
	var TW : Tween = create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	TW.tween_property(box, "border_width_left", 0, duration)
	TW.tween_property(box, "border_width_right", 0, duration)
