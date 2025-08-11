extends State
class_name EntityState

var entity : CharacterBody3D

func _ready():
	await owner.ready
	entity = owner
