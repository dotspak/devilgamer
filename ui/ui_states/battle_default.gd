extends State

@onready var HUD : BattleHUD = owner

func enter() -> void:
	if HUD.previousState != "guard":
		await HUD.spawn_skills()
		HUD._on_optionChanged(HUD.battleOptions.menuIDX)


# handles the controls while in default state
func update(_delta : float) -> void:
	# switch to actor to the left
	if Input.is_action_just_pressed("switch_actor_left"):
		var idx : int = GameManager.battleScene.formation.get_next_actor_idx(HUD.currentActor, -1)
		var newActor : Actor = GameManager.battleScene.formation.get_actor(idx)
		if newActor != HUD.currentActor:
			set_actor(newActor)

	# switch to actor to the right
	elif Input.is_action_just_pressed("switch_actor_right"):
		var idx : int = GameManager.battleScene.formation.get_next_actor_idx(HUD.currentActor, 1)
		var newActor : Actor = GameManager.battleScene.formation.get_actor(idx)
		if newActor != HUD.currentActor:
			set_actor(newActor)
	
	elif HUD.currentActor.phase == Unit.Phase.SELECTING:
		if Input.is_action_just_pressed("guard"):
			HUD.stateMachine.transition_to("guard")

func set_actor(actor : Actor) -> void:
	HUD.currentActor.battleTimer.paused = should_timer_pause()
	HUD.currentActor = actor
	HUD.currentActor.battleTimer.paused = false
		
	await HUD.spawn_skills()
	HUD._on_optionChanged(0)

func should_timer_pause() -> bool: return HUD.currentActor.phase == Unit.Phase.DEAD

func exit() -> void:
	HUD.previousState = name
