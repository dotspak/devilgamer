extends Container
class_name Cursor

@export_category("Paths")
@export var menuPath : NodePath = self.get_path_to(self)

@export_category("Visual")
@export var moveSpeed : float = 0.1
@export var fadeSpeed : float = 0.3
@export var offset : Vector2 = Vector2.ZERO
@export var timerDelay : float = 0.3

@onready var menuParent = get_node(menuPath)
@onready var rotateDeg : Array = [90, 270, 0, 180]

enum CURSOR_DIR{up, down, left, right}

var cursorIDX : int = 0 :
	set(val):
		cursorIDX = val
		optionChanged.emit(cursorIDX)
		#emit_signal("optionChanged", cursorIDX)
var selectedDir : String = "down"
var hasSpawned : bool = false
var holdTimeout : bool = false

signal optionChanged(idx)
signal optionSelected(idx)

func _ready():
	if !hasSpawned:
		spawn()
	if !is_visible_in_tree():
		toggle_visibility()
	
func _process(_delta):
	if hasSpawned:
		var input : Vector2 = Vector2.ZERO
		
		if any_input():
			holdTimeout = false
			$holdTimer.start(timerDelay)
		
		# cursor input handling
		if Input.is_action_pressed("up"): 
			input.y -= button_held("up")
		elif Input.is_action_pressed("down"): 
			input.y += button_held("down")
		elif Input.is_action_pressed("left"): 
			input.x -= button_held("left")
		elif Input.is_action_pressed("right"): 
			input.x += button_held("right")
		
		if Input.is_action_just_pressed("confirm"):
			optionSelected.emit(select_option())
			#emit_signal("optionSelected", select_option())
		
		# places the cursor
		if menuParent is VBoxContainer: 
			set_cursorPos(floor(cursorIDX + input.y), true)
		elif menuParent is HBoxContainer: 
			set_cursorPos(floor(cursorIDX + input.x), true)
		elif menuParent is GridContainer:
			set_cursorPos(floor(cursorIDX + input.x + input.y * menuParent.columns), true)

func button_held(input : String) -> int:
	# if anything is pressed down, or the holdTimer runs out
	if any_input() || holdTimeout:
		if holdTimeout:
			holdTimeout = false
			$holdTimer.start(0.05)
		elif $holdTimer.is_stopped():
			$holdTimer.start(timerDelay)
		return 1
	
	# on button release
	if Input.is_action_just_released(input):
		$holdTimer.stop()
		holdTimeout = false
	return 0

func select_option() -> int:
	if get_item_at_index(cursorIDX):
		return cursorIDX
	return 0
		
func update_menuPath(dest : NodePath) -> void:
	menuPath = dest
	_ready()
	
func get_item_at_index(idx : int) -> Control:
	if !menuParent: 
		return null
	if idx >= menuParent.get_child_count() || idx < 0: 
		return null
	
	return menuParent.get_child(idx) as Control
	
func set_cursorPos(idx : int, tween : bool) -> void:
	var item = get_item_at_index(idx)
	if !item : 
		return
	var nextPos : Vector2 = calcPos(item)
	
	if tween: 
		var TW = create_tween()
		TW.tween_property(self, "global_position", nextPos, moveSpeed)
	else: 
		global_position = nextPos
		hasSpawned = true
	if cursorIDX != idx:
		cursorIDX = idx
	
func calcPos(item : Control) -> Vector2:
	var pos : Vector2 = Vector2.ZERO
	var itemPos : Vector2 = item.global_position
	var itemSize : Vector2 = item.size
	
	if selectedDir == "down":
		pos = Vector2(itemPos.x + itemSize.x * 0.5 + offset.x, itemPos.y + offset.y) - size * 0.5
	elif selectedDir == "up":
		pos = Vector2(itemPos.x + itemSize.x * 0.5 + offset.x, itemPos.y + offset.y) - size * 0.5
	elif selectedDir == "right":
		pos = Vector2(itemPos.x + offset.x, itemPos.y + itemSize.y * 0.5 + offset.y) - size * 0.5
	elif selectedDir == "left":
		pos = Vector2(itemPos.x + offset.x, itemPos.y + itemSize.y * 0.5 + offset.y) - size * 0.5
	return pos
	
func spawn(dir : CURSOR_DIR = CURSOR_DIR.left) -> void:
	hide()
	$Sprite2D.rotate(rotateDeg[dir])
	$Sprite2D/GPUParticles2D.emitting = true
	
	get_item_at_index(cursorIDX)
	set_cursorPos(cursorIDX, false)
	
	# spawn animation
	show()
	var TW = create_tween()
	TW.tween_property(self, "modulate:a", 1, fadeSpeed).from(0)
	await TW.finished

func deSpawn() -> void:
	# despawn animation
	hasSpawned = false
	$Sprite2D/GPUParticles2D.emitting = false
	var TW = create_tween()
	TW.tween_property(self, "modulate:a", 0, fadeSpeed)
	await TW.finished
	queue_free()
	
func toggle_visibility() -> void:
	var TW = create_tween()
	if is_visible_in_tree():
		TW.tween_property(self, "modulate:a", 0, fadeSpeed)
		await TW.finished
		hide()
	else: 
		modulate.a = 0
		show()
		TW.tween_property(self, "modulate:a", 0, fadeSpeed)
		await TW.finished

func any_input() -> bool:
	return (Input.is_action_just_pressed("up") 
	|| Input.is_action_just_pressed("down")
	|| Input.is_action_just_pressed("left")
	|| Input.is_action_just_pressed("right"))

func _on_hold_timer_timeout():
	holdTimeout = true
