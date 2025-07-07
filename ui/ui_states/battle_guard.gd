extends State

@onready var HUD : BattleHUD = owner
var prevText : String

func enter() -> void:
    GameManager.get_node(HUD.cursorPath).hasSpawned = false
    prevText = HUD.battleOptions.menuTitle.text.replace(HUD.battleOptions.MENU_FX, "")
    HUD.battleOptions.set_menu_text("GUARDING")
    HUD.currentActor.guarding = true
    HUD.guardEffect.show()

func update(_delta) -> void:
    if Input.is_action_just_released("guard"):
        HUD.stateMachine.transition_to("default")

func exit() -> void:
    GameManager.get_node(HUD.cursorPath).hasSpawned = true
    HUD.battleOptions.set_menu_text(prevText)
    HUD.guardEffect.hide()
    HUD.currentActor.guarding = false
    HUD.previousState = name