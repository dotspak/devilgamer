extends Resource
class_name Skill

# the possible targets a skill can have
enum TARGET_TYPES{
    one_foe, 
    all_foe, 
    one_ally, 
    all_ally, 
    t_self,
    rand_1,
    rand_2,
    rand_3}

@export_group("info")
@export var name : String
@export_multiline var description : String
@export var animation : PackedScene
@export var skillTarget : TARGET_TYPES = TARGET_TYPES.one_foe

@export_group("Statistical")
@export_range(-1, 10) var rating : int = 3
@export var castTime : float = 2.0
@export var power : int = 10
@export var variance : int = 3
@export_enum("STR", "MAG", "DEF", "AGI", "VIG") var stat : String = "STR"
@export var isHeal : bool = false
@export_range(0,1) var drain : float = 0
@export var accuracy : float = 0.95
@export var elemChance : float = 0.3
@export var element : Element.Elements
@export var critChance : float = 0.1

@export_group("Buffs + Debuffs")
@export_range(-2, 2) var selfPOW : int = 0
@export_range(-2, 2) var selfRES : int = 0
@export_range(-2, 2) var selfSPD : int = 0
@export_range(-2, 2) var targetPOW : int = 0
@export_range(-2, 2) var targetRES : int = 0
@export_range(-2, 2) var targetSPD : int = 0

var caster : Unit
var targetCounter : int = 0

signal dealDamage(target : Unit)

# plays the skill's animation, waits for its completion
func cast(c : Unit) -> void:
    # gets the animation, default to dummy if null
    var anim : SkillAnim = animation.instantiate() if animation else load(
        "res://data/skills/anims/basicSlash.tscn").instantiate()
    caster = c
    
    # determine how many times the animation should play
    var loops : int = c.target.size() if anim.animType == SkillAnim.ANIM_TYPE.single else 1

    # play the animation for the given amount of times
    for i : int in loops:
        anim = animation.instantiate()
        anim.skill = self
        await play_anim(anim, i)
        await anim.pause()
        targetCounter += 1
    await anim.ending()
    anim.queue_free()


# handles the logic to play/position the animation
func play_anim(anim : SkillAnim, i : int) -> void:
    GameManager.battleScene.spawn_skillAnim(anim)
    if anim.animType == SkillAnim.ANIM_TYPE.screen: anim.global_position = Vector3.ZERO
    else: anim.global_position = caster.target[i].global_position
    anim.play()
    await anim.finished


# emits the damage signal for the determined target(s)
func handle_damage(all : bool = false) -> void:
    if all:
        for u : Unit in caster.target:
            dealDamage.emit(u)
    else:
        if targetCounter < caster.target.size():
            dealDamage.emit(caster.target[targetCounter])


func all_target() -> bool: return skillTarget == TARGET_TYPES.all_ally || skillTarget == TARGET_TYPES.all_foe
func random_target() -> bool: return skillTarget == TARGET_TYPES.rand_1 || skillTarget == TARGET_TYPES.rand_2 || skillTarget == TARGET_TYPES.rand_3
func ally_target() -> bool: return skillTarget == TARGET_TYPES.all_ally || skillTarget == TARGET_TYPES.one_ally