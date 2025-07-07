extends Node3D

func _ready():
	GameManager.run_area_generation()
	loading_time()
	
func loading_time() -> void:
	GameManager.load_area(GameManager.startingArea)