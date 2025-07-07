extends Panel
class_name _ActorHud

const downTextEffects = "[shake][center][font_size=16][color=aa0000]"
const HP_TIME : float = 0.02

@onready var hpBar : ProgressBar = $healthBar
@onready var hpText : Label = $HP
@onready var elemIcon : TextureRect = $elemIcon
@onready var anim : AnimationPlayer = $AnimationPlayer
@onready var turnBar : ProgressBar = $nextTurnBar
@onready var downCount : RichTextLabel = $downcount

var curHP : int = 2000
var actor : Actor :
	set(a):
		actor = a
		if actor.HP > 0: downCount.hide()
		curHP = roundi(actor.HP)

# turn based styleboxes
var def_stylebox : StyleBoxFlat
var ready_stylebox : StyleBoxFlat

func _ready():
	def_stylebox = turnBar.get_theme_stylebox("panel")
	ready_stylebox = def_stylebox.duplicate()
	ready_stylebox.border_color = Color(1,1,0)

func _process(_delta: float) -> void:
	# animates the HP
	set_hp_text()
	
	# color the bar accordingly
	if turnBar.value <= 0: turnBar.add_theme_stylebox_override("panel", ready_stylebox)
	else: turnBar.add_theme_stylebox_override("panel", def_stylebox)

# sets up everything related to a hud
func setup(a : Actor) -> void:
	# set actor ref
	actor = a

	# setup default values
	$name.text = actor.charSheet.name
	hpBar.max_value = actor.charSheet.calc_mhp()
	curHP = roundi(actor.HP)
	elemIcon.texture.region.position.x = actor.element * 6

	# setup signals
	actor.hpChanged.connect(_hp_changed)
	actor.elemChanged.connect(_elem_changed)
	actor.turnPointsChanged.connect(_turn_points_changed)
	
	actor.downCountChanged.connect(_down_changed)
	actor.finishedDying.connect(switch_to_dead_mode)
	actor.revived.connect(switch_to_normal_mode)
	
	# place the actor sprite
	$actorSprite/pos.add_child(actor.model)

# logic for when the actor's HP changed
func _hp_changed(HP : float) -> void:
	var time : float = abs(curHP - HP) * HP_TIME
	var TW : Tween = create_tween().set_parallel()
	TW.tween_property(self, "curHP", HP, time)
	TW.tween_property(hpBar, "value", HP, time)

# logic for when the actor's element changed
func _elem_changed(elem : Element.Elements) -> void:
	elemIcon.texture.region.position.x = elem * 6

# logic for when the actor's turn points change
func _turn_points_changed(points : int) -> void:
	if points >= turnBar.max_value:
		turnBar.value = points
	else:
		create_tween().tween_property(turnBar, "value", points, 0.5)

# determines what the HP text should be, and its tags
func set_hp_text() -> void: hpText.text = str(curHP)

# logic for when the actor's down count changes
func _down_changed(val : int) -> void: downCount.text = downTextEffects + str(val)

# swap to this mode when the actor is dead
func switch_to_dead_mode() -> void: downCount.show()

# swap when the actor is revived
func switch_to_normal_mode() -> void: downCount.hide()