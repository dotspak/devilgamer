extends Timer
class_name Buff

enum BUFF_TAG{atk, def, heal}

@export var isMultiplier : bool = true
@export var buffVal : float = 1.1
@export var duration : float = 60.0
@export var tag : BUFF_TAG = BUFF_TAG.atk
var disabled : bool = false

func _init(_buffVal : float = buffVal, _isMultiplier : bool = isMultiplier, _duration : float = duration) -> void:
    isMultiplier = _isMultiplier
    buffVal = _buffVal
    duration = _duration

func _ready():
    wait_time = duration
    reset_buff()
    timeout.connect(end_buff)

func reset_buff() -> void: start()

func end_buff() -> void:
    disabled = true
    queue_free()

func buff_value(amount : float) -> float:
    if isMultiplier: amount *= buffVal
    else: amount += buffVal
    return amount