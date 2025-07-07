# enemyScript.gd -------------------------------------------
# used to create AI for enemies in battle. This script can be used
# to give extremly primative and basic AI, but is intended to be
# extended for best results
extends Node
class_name EnemyScript

@onready var enemy : Unit = get_parent()

# call to make the enemy choose an action, every enemyScript should override this
func choose_action() -> void: full_random()

# randomly chooses a skill, then a valid target for it
func full_random() -> void:
    enemy.select_random_skill()
    enemy.target.append(GameManager.battleScene.formation.get_actors().pick_random())