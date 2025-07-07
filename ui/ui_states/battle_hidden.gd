extends State

@onready var HUD : BattleHUD = owner

func exit() -> void: HUD.previousState = name