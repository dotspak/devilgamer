extends Node
class_name PlayerAttackController

enum FireSlot { PRIMARY, SECONDARY }
enum Phase { READY, CASTING, ATTACKING }

@export var model : EpiaSkin

var phase : Phase = Phase.READY
var currentGear : Gear

# first calls the respective cast animation (cast_swing)
# then calls the attack animation (attack_swing)
func call_attack(usedGear : Gear) -> void:
    currentGear = usedGear

    phase = Phase.CASTING
    model.cast(currentGear.attackType, currentGear.currentFire.castTime)
    await currentGear.castFinished

    phase = Phase.ATTACKING
    model.attack(currentGear.attackType, currentGear.currentFire.attackSpeed)
    await currentGear.attackFinished

    phase = Phase.READY