extends Control
class_name PlayerHud

const HP_HEADER : String = "[font_size=24]"
const ZERO_COLOR : String = "[color=555]"
const NORM_COLOR : String = "[color=fff]"
const OVERHEALTH_COLOR : String = "[color=0f3]"

@onready var hpLabel : RichTextLabel = %hpText
@onready var hpBar : ProgressBar = %hpBar
@onready var hpDragBar : ProgressBar = %hpDragBar
@onready var hpRefillBar : ProgressBar = %hpRefillBar
@onready var hpSegments : Panel = %hpSeg
@onready var ohpBar : ProgressBar = %ohpBar

@onready var bpBar : ProgressBar = %bpBar
@onready var bpRefillBar : ProgressBar = %bpRefillBar
@onready var bpSegments : Panel = %bpSeg

@onready var fullHUD : Control = $VBoxContainer

var player : OWPlayer

var mhp : float = 100 :
	set(val):
		mhp = val
		update_maxes()

var hp : float = 100 :
	set(val):
		hp = val
		hpBar.value = hp
		if hp > mhp: ohpBar.value = hp
		else: ohpBar.value = 0

		dragTimer.stop()
		dragTimer.start()
		update_hp_label()

var mbp : float = 100:
	set(val):
		mbp = val
		update_maxes()

var bp : float = 100:
	set(val):
		bp = val
		bpBar.value = bp
		

var originalHudPos : Vector2 = Vector2.ZERO
var shakeTween : Tween

var dragTimer : Timer 

func _ready():
	dragTimer = Timer.new()
	dragTimer.one_shot = true
	dragTimer.wait_time = 0.5
	add_child(dragTimer)
	dragTimer.timeout.connect(_update_drag_bar)

	hpDragBar.value = mhp
	hpBar.value = mhp


func _on_player_changed(_player: OWPlayer) -> void:
	if !_player.is_node_ready(): await _player.ready
	player = _player
	mhp = player.healthComponent.maxHealth
	hp = player.healthComponent.health
	mbp = player.bpComponent.maxBP
	bp = player.bpComponent.BP

	player.healthComponent.mhpChanged.connect(mhp_changed)
	player.healthComponent.hpChanged.connect(hp_changed)
	hpRefillBar.max_value = PlayerHealthComponent.HP_REFILL_TIME

	player.bpComponent.bpChanged.connect(bp_changed)
	player.bpComponent.maxBpChanged.connect(mbp_changed)
	bpRefillBar.max_value = BPComponent.BP_REFILL_TIME


func _process(_delta : float) -> void:
	if player:
		hpRefillBar.value = player.healthComponent.refillTimer.wait_time - player.healthComponent.refillTimer.time_left
		if hpRefillBar.value >= hpRefillBar.max_value: hpRefillBar.value = 0

		bpRefillBar.value = player.bpComponent.refillTimer.wait_time - player.bpComponent.refillTimer.time_left
		if bpRefillBar.value >= bpRefillBar.max_value: bpRefillBar.value = 0


func hp_changed(_hp : float) -> void:
	var TW = create_tween().set_trans(Tween.TRANS_SINE)
	var time : float = (mhp / _hp) * 0.1
	if _hp < hp: shake_hud(time)
	TW.tween_property(self, "hp", _hp, time)


func mhp_changed(_mhp : float) -> void: 
	mhp = _mhp
	update_maxes()


func update_maxes() -> void:
	hpBar.max_value = mhp
	ohpBar.max_value = mhp * HealthComponent.OVERHEALTH_RATIO
	ohpBar.min_value = mhp
	hpDragBar.max_value = mhp
	bpBar.max_value = mbp
	segment_hp()
	segment_bp()


func segment_hp() -> void:
	var numUpgrades : int = GameManager.player.healthComponent.healthUpgrades
	var length : float = hpSegments.size.x / numUpgrades
	var stylebox : StyleBoxTexture = hpSegments.get("theme_override_styles/panel")
	stylebox.region_rect.size.x = length


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
	if rest.length() > 0: 
		if hp > mhp: finalText += OVERHEALTH_COLOR
		else: finalText += NORM_COLOR
		finalText += rest

	hpLabel.text = finalText


func bp_changed(_bp : float) -> void:
	var TW = create_tween().set_trans(Tween.TRANS_SINE)
	var time : float = (mbp / _bp) * 0.1
	TW.tween_property(self, "bp", _bp, time)


func mbp_changed(_mbp : float) -> void:
	mbp = _mbp
	update_maxes()


func segment_bp() -> void:
	var numUpgrades : int = GameManager.player.bpComponent.bpUpgrades
	var length : float = bpSegments.size.x / numUpgrades
	var stylebox : StyleBoxTexture = bpSegments.get("theme_override_styles/panel")
	stylebox.region_rect.size.x = length


func _update_drag_bar() -> void:
	var TW = create_tween().set_trans(Tween.TRANS_SINE)
	TW.tween_property(hpDragBar, "value", hp, 0.4)


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
