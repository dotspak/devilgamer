extends State

@onready var HUD : BattleHUD = owner

func enter() -> void:
    await HUD.spawn_units()
    HUD._on_optionChanged(0)

func update(_delta : float) -> void:
    if Input.is_action_just_pressed("ui_cancel"):
        HUD.despawn_cursor()
        stateMachine.transition_to("default")

func exit() -> void: HUD.previousState = name