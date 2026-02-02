extends Resource
class_name PlayerAttackData

enum AttackType{ SWING, STAB, QUICKSHOT, BIGSHOT, CAST }

@export var attackType : AttackType = AttackType.SWING
@export var castTime : float = 0.2
@export var attackSpeed : float = 0.3
@export var cooldown : float = 0.2
@export var animation : String
@export var skill : Skill