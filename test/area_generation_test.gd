extends Node3D
@export var startingArea : Area.AREA_IDS

func _ready():
	GameManager.run_area_generation()
	loading_time()
	
func loading_time() -> void:
	if startingArea < 0: startingArea = GameManager.startingArea as Area.AREA_IDS
	GameManager.load_area(startingArea)