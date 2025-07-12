extends Node3D
@export var startingArea : String

func _ready():
	GameManager.run_area_generation()
	loading_time()
	
func loading_time() -> void:
	if !startingArea: startingArea = GameManager.startingArea
	GameManager.load_area(startingArea)