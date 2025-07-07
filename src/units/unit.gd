extends Node3D
class_name Unit

enum Phase {WAITING, SELECTING, CASTING, QUEUED, DEAD}

# basic stats
var charSheet : CharSheet # holds the information about the given unit
var HP : float = 100 :
	set(val):
		HP = clamp(val, 0, charSheet.MHP)
		hpChanged.emit(HP)

		if HP <= 0: 
			trigger_death()

var element : Element.Elements :
	set(val):
		element = val
		elemChanged.emit(element)
var skillList : Array[Skill]
var model : Node3D

# buffs/debuffs
var POW : int = 0 :
	set(val):
		POW = clamp(val, -GameConstants.MAX_BUFF, GameConstants.MAX_BUFF)
var RES : int = 0 :
	set(val):
		POW = clamp(val, -GameConstants.MAX_BUFF, GameConstants.MAX_BUFF)
var SPD : int = 0 :
	set(val):
		POW = clamp(val, -GameConstants.MAX_BUFF, GameConstants.MAX_BUFF)

var guarding : bool = false

# turn variables
var phase : Phase :
	set(val):
		phase = val
		phaseChanged.emit(phase)
var selectedSkill : Skill
var target : Array[Unit]
var baseSpd : float = 0
var battleTimer : Timer = Timer.new()

# signals
signal phaseChanged(phase : Phase)
signal timerElapsed(unit : Unit)
signal turnEnded
signal finishedDying
signal hpChanged(newHP : float)
signal elemChanged(newElem : Element.Elements)

# simply initializes the character sheet
func _init(sheet : CharSheet) -> void: charSheet = sheet


# sets up the unit based on the data given
func _ready() -> void:
	skillList = charSheet.skillList.duplicate()
	if skillList.is_empty():
		skillList.append(load("res://data/skills/attack.tres"))
	charSheet.calc_mhp()

	# gets the initial speed of a unit
	set_baseSpd()

	# set up the HP and the elements
	HP = charSheet.MHP
	element = charSheet.baseElement

	# setup the timer
	add_child(battleTimer)
	battleTimer.timeout.connect(func(): timerElapsed.emit(self))


# determines what the speed of the waiting timer should be
func set_baseSpd() -> void:
	var AGI : int = charSheet.stats["AGI"]
	AGI = 21 - clamp(AGI, 1, 20)
	baseSpd = (2.0 + ((AGI - 1) / 19.0) * (2.0 - 0.5))
	baseSpd = clamp(baseSpd, 0.1, 2.0)


func start_battle() -> void:
	enter_waiting_phase()


# phase controls
func enter_waiting_phase() -> void:
	battleTimer.start(baseSpd)
	phase = Phase.WAITING
	

func enter_casting_phase() -> void:
	battleTimer.start(selectedSkill.castTime)
	phase = Phase.CASTING


func enter_selecting_phase() -> void:
	battleTimer.stop()
	phase = Phase.SELECTING


func enter_queued_phase() -> void:
	battleTimer.stop()
	phase = Phase.QUEUED


# uses the skill chosen through skill selection
func use_skill() -> void:
	if !selectedSkill: return
	selectedSkill = selectedSkill.duplicate()
	
	# play the skill's animation, call dealing damage when the signal is emitted
	selectedSkill.dealDamage.connect(deal_damage)
	GameManager.battleScene.HUD.display_top_text(selectedSkill.name, 1, selectedSkill.element)

	# cast the spell
	await cast_anim()
	await selectedSkill.cast(self)
	selectedSkill.dealDamage.disconnect(deal_damage)


# calculates the damage of a skill. Usually used for actually attacking,
# but a skill can be passed to figure out it's base damage.
func calc_skill_dmg(skillTest : Skill = null) -> float:
	var skill : Skill = selectedSkill if !skillTest else skillTest
	var stat : float = charSheet.stats[skill.stat]
	var elemBoost : float = (GameConstants.ELEM_BOOST_MOD 
		if element == selectedSkill.element || element == charSheet.baseElement else 1.0)
	var buffMod : float = get_buff_mod(POW)
	return (skill.power + stat + randi_range(-skill.variance, skill.variance)) * elemBoost * buffMod


# handles dealing damage to the passed in unit
func deal_damage(targetUnit : Unit) -> void:
	if !selectedSkill: return

	# handles the damage type
	if selectedSkill.isHeal: targetUnit.heal_damage(calc_skill_dmg())
	else:
		var accuracy : float = selectedSkill.accuracy if element != Element.Elements.HOLY else 0.5
		var dmg = targetUnit.take_damage(
			self, 					# the unit dealing the damage
			calc_skill_dmg(), 		# determines the skill damage
			accuracy, 				# accuracy of the hit
			selectedSkill.element,	# element of the skill
			randf_range(0, 1) < selectedSkill.critChance # critical hit chance
		)
		
		# handles if the attack hits
		if dmg > 0:
			# affect the buff levels of the target
			targetUnit.damage_anim()
			if targetUnit.HP > 0:
				targetUnit.POW += selectedSkill.targetPOW
				targetUnit.RES += selectedSkill.targetRES
				targetUnit.SPD += selectedSkill.targetSPD
		else:
			GameManager.battleScene.HUD.display_damage_nums(0, targetUnit)
			print("MISSED!")


# deals damage to this unit based on the dmg passed and the element.
# returns true if the hit went through, false if missed.
func take_damage(
	caster : Unit,
	amount : float, acc : float, 
	elem : Element.Elements = Element.Elements.NONE, 
	crit : bool = false, 
	pierce : bool = false) -> float:
	# check accuracy
	if !does_attack_hit(caster, acc): return 0

	# guaranteed crit if the target is wet
	if element == Element.Elements.AQUA: crit = true

	# handles elemental logic
	var elemMod : float = 1
	if elem:
		# handles elemental reaction
		var reactionPower : float = Element.reaction_ref(elem, element)
		elemMod = reactionPower
		if reactionPower > 1:
			element = charSheet.baseElement
		
		# handles elemental resistance
		if elem == charSheet.baseElement:
			elemMod *= GameConstants.RESIST_MOD
	
	# multiply the damage by the elemental mode
	amount *= elemMod

	# handles critical hits
	if crit:
		amount *= 1.5
		print("CRITICAL HIT")

	# handle defense reduction
	if !pierce: 
		amount = ceili(amount - (charSheet.stats["DEF"] * GameConstants.DEF_SCALE) * get_buff_mod(-RES))
	
	# ensures damage is always at least 1 if it didn't miss
	amount = max(amount, 1)

	# display damage effects
	var bldAmt : float = (amount / charSheet.MHP) * 200
	bldAmt = max(bldAmt, 40)
	print(charSheet.name, " took ", amount, " DMG!\n")
	GameManager.battleScene.HUD.display_damage_nums(amount, self, crit, elemMod)
	#GameManager.battleScene.display_blood_splatter(bldAmt, self)

	# deal the damage
	HP -= amount

	return amount


# calculates the accuracy of a given attack
func does_attack_hit(caster : Unit, acc : float) -> bool:
	# handles the holy and vile accuracy checks. Cancel each other 
	# out if the caster is holy and the target is vile
	if element == Element.Elements.VILE:
		if caster.element != Element.Elements.HOLY:
			return true
	
	# basic accuracy check
	if randf_range(0,1.0) <= acc: return true
	return false


# returns the buff modification value of the passed buff lvl
# ex. passing POW = 4 returns 4 * 0.45 = 1.8
func get_buff_mod(buffLVL : int) -> float:
	var mod : float = 1.0
	mod = mod + (buffLVL * GameConstants.BUFF_SCALE)
	return mod


# healing logic
func heal_damage(healAmount : float) -> float:
	healAmount = ceili(healAmount)
	GameManager.battleScene.HUD.display_damage_nums(healAmount, self, false, 1, true)
	#GameManager.battleScene.display_heal_splatter(self)
	HP += healAmount
	return healAmount


# triggers the damage animation of the unit's model
func damage_anim() -> void:
	if !model: return
	await model.jump()


# triggers the death animation of the unit's model
func death_anim() -> void:
	if !model: return
	await model.jump()


# basic cast animation for now
func cast_anim() -> void:
	if !model: return
	await model.jump()


# starts the unit's turn logic
func start_turn() -> void:
	# use the selected skill
	await use_skill()
	end_turn()


# ends the unit's turn
func end_turn() -> void:
	# reset all options
	selectedSkill = null
	target.clear()
	turnEnded.emit()
	enter_waiting_phase()


# starts the process of a unit perishing
func trigger_death() -> void:
	battleTimer.stop()
	phase = Phase.DEAD
	print(charSheet.name, " DIED!\n")
	await death_anim()
	finishedDying.emit()


# chooses a random skill from the skill list
func select_random_skill() -> Skill: 
	selectedSkill = skillList.pick_random()
	return selectedSkill


func is_resisted(attackingElement : Element.Elements) -> float:
	if Element.is_elemental(attackingElement):
		if attackingElement == charSheet.baseElement:
			return 0.5
	return 1


func display_phase() -> void: print(charSheet.name, " is in phase: ", Phase.keys()[phase])