extends Control
class_name PlayerHud

const HP_HEADER : String = "[font_size=24]"
const ZERO_COLOR : String = "[color=555]"
const NORM_COLOR : String = "[color=fff]"

@onready var hpLabel : RichTextLabel = %hpText
@onready var hpBar : ProgressBar = %bar
@onready var dragBar : ProgressBar = %dragBar
@onready var fullHUD : Control = $VBoxContainer

var mhp : float = 100 :
	set(val):
		mhp = val
		update_maxes()

var hp : float = 100 :
	set(val):
		hp = val
		hpBar.value = hp
		dragTimer.stop()
		dragTimer.start()
		update_hp_label()

var originalHudPos : Vector2 = Vector2.ZERO
var shakeTween : Tween

var dragTimer : Timer 

func _ready():
	dragTimer = Timer.new()
	dragTimer.one_shot = true
	dragTimer.wait_time = 0.5
	add_child(dragTimer)
	dragTimer.timeout.connect(_update_drag_bar)

	dragBar.value = mhp
	hpBar.value = mhp


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
	update_maxes()


func update_maxes() -> void:
	hpBar.max_value = mhp
	dragBar.max_value = mhp


func hp_changed(_hp : float) -> void:
	var TW = create_tween().set_trans(Tween.TRANS_SINE)
	var time : float = (mhp / _hp) * 0.1
	if _hp < hp: shake_hud(time)
	TW.tween_property(self, "hp", _hp, time)


func _update_drag_bar() -> void:
	var TW = create_tween().set_trans(Tween.TRANS_SINE)
	TW.tween_property(dragBar, "value", hp, 0.4)


func _on_player_changed(player: OWPlayer) -> void:
	mhp = player.stats.get_stat(StatComponent.STATS.MHP)
	hp = player.stats.HP

	player.stats.mhpChanged.connect(mhp_changed)
	player.stats.hpChanged.connect(hp_changed)


func shake_hud(duration : float = 0) -> void:
	if duration <= 0:
		duration = 0.15

	if originalHudPos == Vector2.ZERO: originalHudPos = fullHUD.position
	if shakeTween && shakeTween.is_running(): shakeTween.kill()

	shakeTween = create_tween().set_trans(Tween.TRANS_SINE)

	var steps : int = 12
	var shakeStrength : int = 12
	for i in steps:
		var offset : Vector2 = Vector2(randf_range(-shakeStrength, shakeStrength), randf_range(-shakeStrength, shakeStrength))
		shakeTween.tween_property(fullHUD, "position", originalHudPos + offset, duration / steps)
	
	shakeTween.tween_property(fullHUD, "position", originalHudPos, duration / steps)
