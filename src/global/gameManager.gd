@icon("res://icons/gameManager.svg")
# gameManager.gd ------------------------------------
# stores global values and references, ie) party info,
# current scene, if in battle, etc.
extends Node

const CURSOR : PackedScene = preload("res://ui/cursor.tscn")
const PLAYER_SCENE : PackedScene = preload("res://scenes/player/owPlayer3D.tscn")

@onready var dialogueWindow : Control = %dialogue
@onready var mainMenu : MainMenu = %mainMenu
@onready var battleHud : Control = %battleHud
@onready var battleBar : BattleActions = %battleBar
@onready var epiaHud : PlayerHud = %epiaHud

# Debug Tools --------------------------
var DEBUG_MODE : bool = false

# Flow Control --------------------------
var CHESTS : Dictionary[String, Dictionary]

# Character Control --------------------------
var player : OWPlayer :
	set(val):
		player = val
		print("Player set to: ", player)
		playerChanged.emit(val)

# World Management ----------------------------
@export var areas : Array[Area]
var generatedAreas : Dictionary[String, AreaDef] = {}
var startingArea : String = ""

@onready var fadeAnim : AnimationPlayer = %fadeAnims

const WATERALPHA : float = 0.5
var isUnderwater : bool = false

signal playerChanged(player : OWPlayer)
signal areasGenerated
signal areaLoaded

func _ready() -> void:
	fetch_scene()
	battleHud.hide()
	DEBUG_MODE = OS.is_debug_build()

	instance_player()
	spawn_player()


func _process(_delta : float) -> void:
	if OS.is_debug_build():
		if Input.is_action_just_pressed("ENTER_DEBUG"): 
			DEBUG_MODE = !DEBUG_MODE
			print("DEBUG MODE: ", DEBUG_MODE)
		if Input.is_action_just_pressed("OPEN_CONSOLE"):
			$debugConsole.visible = !$debugConsole.visible
			if $debugConsole.visible:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				player.inputAllowed = false
			else:
				player.inputAllowed = true

	if Input.is_action_just_pressed("window_toggle"):
		toggle_fullscreen()
		


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton && event.pressed: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("ui_cancel"): Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if mainMenu.visible:
		mainMenu.phoneScreen.push_input(event, true)


func toggle_fullscreen():
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN
		else DisplayServer.WINDOW_MODE_WINDOWED
	)

# SCENE MANAGEMENT --------------------------------------------
@onready var sceneView : Node = %scene
@onready var currentScene : Node = null

# grabs the current scene, mainly for boot.
func fetch_scene() -> void:
	var scene : Node = get_tree().current_scene
	scene.get_parent().remove_child.call_deferred(scene)
	sceneView.add_child.call_deferred(scene)
	currentScene = scene


# adds the passed scene as a child to the sceneview and stores the reference to it
func set_current_scene(scene : Node) -> void: 
	if currentScene: currentScene.queue_free()
	sceneView.add_child(scene)
	currentScene = scene


# trigger area generation for the game
func run_area_generation() -> void:
	for area in areas:
		var def : AreaDef = area.generate_area_def()
		generatedAreas[def.areaName] = def
		if startingArea == "": startingArea = def.areaName
	areasGenerated.emit()
	print("finished generating areas")


func spawn_cursor(parent : Node, target : Node, 
	onMove : Callable, onSelect : Callable, 
	offset : Vector2 = Vector2(-16,0), dir : Cursor.CURSOR_DIR = Cursor.CURSOR_DIR.left) -> NodePath:
		var c : Cursor = CURSOR.instantiate()
		c.offset = offset
		c.optionChanged.connect(onMove)
		c.optionSelected.connect(onSelect)
		c.name = "Cursor"
		parent.add_child(c)
		c.spawn(dir)
		c.update_menuPath(c.get_path_to(target))
		return get_path_to(c)


func instance_player() -> OWPlayer:
	var p : OWPlayer = PLAYER_SCENE.instantiate()
	sceneView.add_sibling(p)
	player = p
	CameraManager.playerMainCam = player.mainCam
	CameraManager.playerLockCam = player.lockCam
	CameraManager.playerMenuCam = player.menuCam
	return player


func spawn_player(spawnPos : Vector3 = Vector3.ZERO, spawnRot : float = 0) -> OWPlayer:
	player.show()
	player.velocity = Vector3.ZERO
	player.global_position = spawnPos
	player.model.rotation = Vector3(0, spawnRot, 0)

	await get_tree().process_frame
	player.stateMachine.transition_to("idle")
	player.camera.make_current()

	return player


func despawn_cursor(path : NodePath) -> void:
	if get_node_or_null(path) is Cursor:
		get_node(path).deSpawn()
		path = ""


# fades the screen to the passed color for the given amount of time using the passed fader
enum fadeTargets {DEF, AREA}
var prevObject : Dictionary
func fadeout_screen(time : float = 1.0, color : Color = Color.BLACK, fader : fadeTargets = fadeTargets.DEF) -> void:
	var fadeObject : Dictionary = get_fade_object(fader)
	var fadeTween : Tween = create_tween()
	prevObject = fadeObject
	fadeObject.node.color = color

	if fadeObject.node == %fader:
		fadeTween.tween_property(
			fadeObject.node, "modulate:a", 1.0, time).from(0)
	else:
		fadeTween.tween_property(
			fadeObject.node.material, "shader_parameter/progress", fadeObject.end, time).from(fadeObject.start)

	await fadeTween.finished


# fades the screen back in from black for the given amount of time
func fadein_screen(time : float = 1.0, color : Color = Color.BLACK, fader : fadeTargets = fadeTargets.DEF) -> void:
	var fadeObject : Dictionary = get_fade_object(fader)
	var fadeTween : Tween = create_tween()
	fadeObject.node.color = color

	if fadeObject.node == %fader:
		fadeTween.tween_property(
			fadeObject.node, "modulate:a", 0, time).from(1.0)
	else: 
		fadeTween.tween_property(
			fadeObject.node.material, "shader_parameter/progress", fadeObject.start, time).from(fadeObject.end)

	if prevObject:
		if prevObject.node == %fader:
			prevObject.node.modulate.a = 0
		else:
			prevObject.node.material.set_shader_parameter("progress", prevObject.start)

	await fadeTween.finished


func get_fade_object(fader : fadeTargets) -> Dictionary:
	var object : Dictionary = {"node" : null, "start" : 0, "end" : 1.0}
	match(fader):
		fadeTargets.AREA:
			object.node = %areaFader
			object.start = -0.5
			object.end = 4
		_: object.node = %fader
	
	if fader != fadeTargets.DEF:
		object.node.material.set_shader_parameter("progress", object.start)
	return object


# handles visual effect changes when entering water
func handle_water_change(color : Color = Color.ALICE_BLUE) -> void:
	var waterOverlay : Control = %waterOverlay
	var TW : Tween = create_tween()
	%wavy.material.set_shader_parameter("color", color)
	TW.tween_property(%wavy.material, "shader_parameter/alpha", WATERALPHA, 0.2).from(0)
	waterOverlay.show()
	AudioManager.play_ui_sfx("enterWater")
	AudioManager.set_lowpass(true)
	await TW.finished


# removes visual effects changes when exiting water
func handle_water_exit() -> void:
	hide_breath_bar()
	var waterOverlay : Control = %waterOverlay
	var TW : Tween = create_tween()
	TW.tween_property(%wavy.material, "shader_parameter/alpha", 0, 0.2).from(WATERALPHA)
	AudioManager.set_lowpass(false)
	await TW.finished
	waterOverlay.hide()


# --------------------------------------------------------------------
# Area/Room Controls 
# --------------------------------------------------------------------
@onready var nameLabel : RichTextLabel = $AreaIntro/Control/areaName
@onready var descLabel : RichTextLabel = $AreaIntro/Control/areaDescription
@onready var areaAnimator : AnimationPlayer = $AreaIntro/Control/introAnimator
const NAME_FX : String = "[font_size=40][outline_color=black][outline_size=20][shake][bgcolor=black]"
const DESC_FX : String = "[i][font_size=10][outline_color=black][outline_size=20][shake][bgcolor=black]"
const LETTER_TIME : float = 0.1
const INTRO_Y_POS : float = 20

var currentRoom : RoomInstance
var currentArea : AreaInstance

func animate_intro_text(areaName : String = "dummy", areaDescription: String = "dummy") -> void:
	nameLabel.text = NAME_FX + areaName.capitalize()
	descLabel.text = DESC_FX + areaDescription
	areaAnimator.play("animation")
	await areaAnimator.animation_finished


# white fade out that plays when swapping areas
func change_area_fade() -> void:
	await fadeout_screen(1, Color.WHITE)
	await get_tree().create_timer(0.5).timeout
	await fadein_screen(1, Color.WHITE)


func load_terminal(title : String) -> void:
	var terminal : CanvasLayer = load("res://ui/ui_terminalScreen.tscn").instantiate()
	terminal.targetTitle = title
	if player: player.freeze()
	dialogueWindow.add_child(terminal)
	#set_current_scene(terminal)


# loads the passed area (to) coming from the previous area (from)
func load_area(to : String, from : String = "", color : Color = Color.WHITE) -> void:
	print("attempting to load ", to, ", from ", from)
	player.disable_input()
	
	var areaInstance : AreaInstance = AreaInstance.new(generatedAreas[to])
	set_current_scene(areaInstance)
	currentArea = areaInstance

	if !areaInstance.is_node_ready():
		await areaInstance.ready

	areaInstance.spawn_rooms_from_def()

	# get the spawn position for the player
	var spawnPos : Vector3 = Vector3.ZERO
	var spawnRot : Basis = Basis.IDENTITY

	var enteringRoom : RoomToArea = null
	if areaInstance.areaTransitionRooms.has(from):
		enteringRoom = areaInstance.areaTransitionRooms[from]

	if from == "pool": # coming from a shadow pool
		pass
	elif from != "": # coming from a previous area
		spawnPos = enteringRoom.playerWalkToPos.global_position
	
	print("successfully loaded ", to, "!")

	var forward : Vector3 = -spawnRot.z.normalized()
	var yaw : float = 0
	forward.y = 0
	if forward.length() > 0.001:
		forward = forward.normalized()
		yaw = atan2(forward.x, forward.z)

	spawn_player(spawnPos, yaw)
	CameraManager.enable_main_cam()
	player.camera_to_front()

	if enteringRoom:
		CameraManager.set_active_cam(enteringRoom.areaCam)
		enteringRoom.enter_room()
		enteringRoom.transitionTrigger.monitoring = false
		player.move_to_position(enteringRoom.spawnPoint.global_position)
	else:
		areaInstance.generatedRooms[0].enter_room()

	# play the area intro
	await areaInstance.area_intro(color)
	if player.movingToTarget: await player.movedToPosition
	
	if enteringRoom: enteringRoom.transitionTrigger.monitoring = true
	areaLoaded.emit()
	player.enable_input()
	player.un_freeze()


func load_elevator() -> void:
	var elevatorScene : Node3D = load("res://maps/hub/map_hub_elevator.tscn").instantiate()
	set_current_scene(elevatorScene)



# --------------------------------------------------------------------
# Dialogue Manager function overrides, used for custom setup ---------------------------------
func create_dialogue_window(resource: DialogueResource, title: String = "", extra_game_states: Array = []) -> Node:
	var balloon_path: String = "res://ui/dialogue/ui_msgBox2.tscn"
	if not ResourceLoader.exists(balloon_path):
		balloon_path = "res://ui/dialogue/ui_msgBox2.tscn"
	return DialogueManager.show_dialogue_balloon_scene(balloon_path, resource, title, extra_game_states)


func show_dialogue_balloon_scene(balloon_scene, resource: DialogueResource, title: String = "", extra_game_states: Array = []) -> Node:
	if balloon_scene is String:
		balloon_scene = load(balloon_scene)
	if balloon_scene is PackedScene:
		balloon_scene = balloon_scene.instantiate()

	var balloon: Node = balloon_scene
	_start_balloon.call_deferred(balloon, resource, title, extra_game_states)
	return balloon


func _start_balloon(balloon: Node, resource: DialogueResource, title: String, extra_game_states: Array) -> void:
	dialogueWindow.add_child(balloon)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if balloon.has_method(&"start"):
		balloon.start(resource, title, extra_game_states)
	elif balloon.has_method(&"Start"):
		balloon.Start(resource, title, extra_game_states)
	else:
		assert(false, DMConstants.translate(&"runtime.dialogue_balloon_missing_start_method"))

	DialogueManager.dialogue_started.emit(resource)
	DialogueManager.bridge_dialogue_started.emit(resource)


func enter_focus_ui() -> void:
	var anim : AnimationPlayer = %uiAnimator2
	anim.play("enterFocus")
	await anim.animation_finished


func exit_focus_ui() -> void:
	var anim : AnimationPlayer = %uiAnimator2
	anim.play_backwards("enterFocus")
	await anim.animation_finished


func show_battle_ui() -> void:
	battleHud.show()
	var anim : AnimationPlayer = %uiAnimator
	anim.play("displayBattleHUD")
	await anim.animation_finished


func hide_battle_ui() -> void:
	var anim : AnimationPlayer = %uiAnimator
	anim.play_backwards("displayBattleHUD")
	await anim.animation_finished
	battleHud.hide()


func change_max_breath(val : float) -> void: 
	%airProgress.max_value = val
	$UI/breathBar.hide()

func update_breath_bar(val : float) -> void:
	%airProgress.value = max(val, 0.01)
	if %airProgress.max_value - val >= 1.0:
		if !$UI/breathBar.visible:
			show_breath_bar()


func show_breath_bar() -> void:
	var container : Control = $UI/breathBar
	container.show()
	var TW : Tween = create_tween().set_parallel()

	TW.tween_property(container, "position:y", 0, 0.2).from(-20).set_trans(Tween.TRANS_BACK)
	TW.tween_property(container, "modulate:a", 1, 0.2).from(0)
	await TW.finished


func hide_breath_bar() -> void:
	var container : Control = $UI/breathBar
	var TW : Tween = create_tween().set_parallel()

	TW.tween_property(container, "position:y", -20, 0.2)
	TW.tween_property(container, "modulate:a", 0, 0.2)
	await TW.finished
	container.hide()


func add_ui(node : Node) -> void: $UI.add_child(node)

func play_static(duration : float = 0.5) -> void:
	var anim : AnimationPlayer = %staticAnim
	var time : float = pow(duration, -1)
	anim.speed_scale = time
	anim.play("static")
	await anim.animation_finished


func game_over() -> void: print("GAME OVER!")

func display_menu() -> void:
	if !mainMenu.visible:
		player.freeze()
		battleHud.hide()
		enter_focus_ui()
		mainMenu.display()
	else:
		if !mainMenu.isFullMenu:
			player.un_freeze()
			show_battle_ui()
			exit_focus_ui()
			mainMenu.undisplay()
