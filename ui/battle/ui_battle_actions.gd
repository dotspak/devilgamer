extends Control
class_name BattleActions

const ICON_IDX : int = 0
const STACK_IDX : int = 1
const LABEL_HEADER : String = "[bgcolor=000]> "
const STACK_HEADER : String = "[outline_size=4][outline_color=000]"

@onready var gearBox : HBoxContainer = %gear
@onready var selectedLabel : RichTextLabel = %selectedLabel

var gear : Array[Gear] = [] :
	set(val):
		if val.is_empty(): return
		gear = val
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
				g.stacksChanged.connect(stacks_changed.bind(g))
			else:
				slot.get_child(ICON_IDX).texture = null
				slot.get_child(STACK_IDX).text = ""
				slot.modulate.a = 0.5

		slotIDX = 0

var slotIDX : int = 0 :
	set(val):
		if gear.is_empty(): return

		var prevIDX : int = slotIDX
		slotIDX = clamp(val, 0, max(get_gear_amount() - 1, 0))

		animate_deselect(gearBox.get_child(prevIDX))
		aninmate_select(gearBox.get_child(slotIDX))
		
		if selectedLabel:
			var text : String = gear[slotIDX].gearName if get_gear_amount() > 0 else "NULL"
			selectedLabel.text = LABEL_HEADER + text

		if prevIDX != slotIDX:
			AudioManager.play_ui_sfx("cursor")


func _unhandled_input(_event: InputEvent) -> void:
	if GameManager.player.inputAllowed:
		if Input.is_action_just_pressed("skill_up"): slotIDX += 1
		elif Input.is_action_just_pressed("skill_down"): slotIDX -= 1


func stacks_changed(stacks : int, g : Gear) -> void:
	var idx : int = get_gear_idx(g)
	if idx >= 0:
		var finalNum : String = str(stacks) if stacks > 0 else ""
		print(finalNum)
		gearBox.get_child(idx).get_child(STACK_IDX).text = STACK_HEADER + str(finalNum)


func get_gear_idx(g : Gear) -> int:
	for i : int in gear.size():
		if g == gear[i]:
			return i
	return -1


func get_gear_amount() -> int:
	var total : int = 0
	for n in gear: if n: total += 1
	return total


func aninmate_select(slot : PanelContainer) -> void:
	var box : StyleBoxFlat = slot.get_theme_stylebox("panel")
	var TW : Tween = create_tween().set_parallel()
	TW.tween_property(box, "border_width_left", 4, 0.1)
	TW.tween_property(box, "border_width_right", 4, 0.1)


func animate_deselect(slot : PanelContainer) -> void:
	var box : StyleBoxFlat = slot.get_theme_stylebox("panel")
	var TW : Tween = create_tween().set_parallel()
	TW.tween_property(box, "border_width_left", 0, 0.1)
	TW.tween_property(box, "border_width_right", 0, 0.1)
