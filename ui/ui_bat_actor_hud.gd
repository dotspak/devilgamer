extends Control
class_name ActorHud

const downTextEffects = "[shake][center][font_size=16][color=aa0000]"
const HP_TIME : float = 0.03

@onready var hpBar : TextureProgressBar = %mainHP
@onready var drainBar : TextureProgressBar = %drainDelay
@onready var hpText : RichTextLabel = %hpText
@onready var elemIcon : TextureRect = %status
@onready var anim : AnimationPlayer = $AnimationPlayer
@onready var atbParticle : GPUParticles2D = %atbParticle

var curHP : int = 999
var actor : Actor :
	set(a):
		actor = a
		$name.text = actor.charSheet.name
		curHP = roundi(actor.HP)
		hpBar.max_value = actor.charSheet.MHP
		drainBar.max_value = actor.charSheet.MHP
		hpBar.value = curHP
		drainBar.value = curHP
		elemIcon.texture.region.position.x = actor.element * 16

		# setup signals
		actor.hpChanged.connect(_hp_changed)
		actor.elemChanged.connect(_elem_changed)	
		actor.finishedDying.connect(switch_to_dead_mode)
		actor.revived.connect(switch_to_normal_mode)
		actor.phaseChanged.connect(_on_phase_change)

func _process(_delta: float) -> void:
	set_hp_text()
	if actor:
		if actor.phase != Unit.Phase.QUEUED:
			var ratio : float = actor.battleTimer.time_left / actor.battleTimer.wait_time
			atbParticle.amount_ratio = 1 - ratio
		

func _on_phase_change(phase : Unit.Phase) -> void:
	anim.play("ringwipe")
	await get_tree().create_timer(0.5).timeout

	var TW : Tween = create_tween()
	TW.tween_property(atbParticle, "speed_scale", 1.4, 0.5)
	match actor.phase:
		Unit.Phase.WAITING: atbParticle.self_modulate = Color.WHITE
		Unit.Phase.CASTING: atbParticle.self_modulate = Color.CADET_BLUE
		Unit.Phase.QUEUED: atbParticle.amount_ratio = 0
		Unit.Phase.SELECTING: atbParticle.self_modulate = Color.YELLOW
		Unit.Phase.DEAD: atbParticle.self_modulate = Color.DARK_ORCHID
	TW.tween_property(atbParticle, "speed_scale", 0.4, 0.5)
	await TW.finished

# logic for when the actor's HP changed
func _hp_changed(HP : float) -> void:
	if HP < curHP: damage_anim()
	var time : float = abs(curHP - HP) * HP_TIME
	var TW : Tween = create_tween().set_parallel().set_trans(Tween.TRANS_QUAD)
	TW.tween_property(self, "curHP", HP, time)
	TW.tween_property(hpBar, "value", HP, time)
	$drainTimer.start()


func _on_drain_timer_timeout() -> void:
	var time : float = abs(drainBar.value - curHP) * HP_TIME
	var TW : Tween = create_tween().set_trans(Tween.TRANS_QUAD)
	TW.tween_property(drainBar, "value", curHP, time)


func set_hp_text() -> void:
	var hpStr : String = str(max(curHP, 0)).pad_zeros(3)
	var zeros: int = 0
	for c : String in hpStr: if c == "0": zeros += 1
	
	var leadingZeros : String = "[color=333]" + hpStr.left(zeros) + "[/color]"
	var coloredText : String = "[color=26d]" + hpStr.right(3 - zeros) + "[/color]"

	hpText.text = (
		"[shake rate=10.0 level=10 connected=1]" +
		"[outline_size=10][center]" +
		leadingZeros + coloredText )


func damage_anim() -> void:
	var TW : Tween = create_tween()
	var power : int = 10
	TW.tween_property(self, "position:x", power, 0.05).from(-power)
	TW.tween_property(self, "position:x", -power, 0.05)
	TW.tween_property(self, "position:x", 0, 0.025)
	await TW.finished


func _elem_changed(elem : Element.Elements) -> void: elemIcon.texture.region.position.x = elem * 6
func switch_to_dead_mode() -> void: pass
func switch_to_normal_mode() -> void: pass
