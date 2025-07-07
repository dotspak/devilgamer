extends State
class_name PlayerState

var player : OWPlayer

func _ready():
	await owner.ready
	player = owner
