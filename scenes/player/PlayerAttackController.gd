extends Node
class_name PlayerAttackController

enum FireSlot { PRIMARY, SECONDARY }
enum Phase { READY, CASTING, ATTACKING }

@export var model : EpiaSkin

var phase : Phase = Phase.READY :
	set(val):
		phase = val
		match(phase):
			Phase.READY:        print("ready to use an attack")
			Phase.CASTING:      print("casting an attack")
			Phase.ATTACKING:    print("using an attack")

# first calls the respective cast animation (cast_swing)
# then calls the attack animation (attack_swing)
func call_attack(usedGear : Gear) -> void:
	get_parent().velocity = Vector3.ZERO
	if !usedGear.currentFire: return

	# cast the attack
	phase = Phase.CASTING
	model.cast(usedGear.currentFire.attackType, usedGear.currentFire.castTime)
	if usedGear.model:
		model.attach_to_hand(usedGear.model)
		usedGear.model.show()
	await usedGear.castFinished

	# use the attack
	phase = Phase.ATTACKING
	model.attack(usedGear.currentFire.attackType, usedGear.currentFire.attackSpeed)
	await usedGear.attackFinished

	# recover/cooldown
	if usedGear.model: 
		usedGear.model.hide()
		usedGear.model.reparent(usedGear)
	phase = Phase.READY
