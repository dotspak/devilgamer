extends Control
class_name PlayerHud

const HP_HEADER : String = "[font_size=20]"
const ZERO_COLOR : String = "[color=555]"
const NORM_COLOR : String = "[color=fff]"

@onready var hpLabel : RichTextLabel = %hpText
@onready var hpBar : ProgressBar = %bar

var mhp : float = 100
var hp : float = 99 :
	set(val):
		hp = val
		hpBar.value = hp
		update_hp_label()


func update_hp_label() -> void:
	var num : String = str(int(clamp(hp, 0, 999))).pad_zeros(3)

	var firstNonZero : int = -1
	for i in num.length():
		if num[i] != "0":
			firstNonZero = i
			break

	if firstNonZero == -1:
		firstNonZero = num.length()

	var zeros : String = num.substr(0, firstNonZero)
	var rest : String = num.substr(firstNonZero)

	var finalText : String = HP_HEADER
	if zeros.length() > 0: finalText += ZERO_COLOR + zeros
	if rest.length() > 0: finalText += NORM_COLOR + rest

	hpLabel.text = finalText


func mhp_changed(_mhp : float) -> void: 
	mhp = _mhp
	hpBar.max_value = mhp


func hp_changed(_hp : float) -> void:
	var TW = create_tween()
	TW.tween_property(self, "hp", _hp, 0.2)


func _on_player_changed(player: OWPlayer) -> void:
	mhp_changed(player.stats.stats[StatComponent.STATS.MHP])
	hp = player.stats.HP
	player.stats.hpChanged.connect(hp_changed)
