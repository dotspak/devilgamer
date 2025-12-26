extends Node
class_name _StatComponent

@export var duration : float = 0
@export var amount : float = 5
@export var isMultiplier : bool = false

var timer : Timer

static func create(node : Node, _amount : float = 1.1, _isMultiplier : bool = true, _duration : float = 60, source : String = "AtkBuff") -> _StatComponent:
    var component : _StatComponent = node.find_child(source)
    if component:
        component.start_timer()
    else:
        component = _StatComponent.new()
        component.duration = _duration
        component.amount = _amount
        component.isMultiplier = _isMultiplier
        
        node.add_child(component)
    return component


func _ready(): _apply_duration()
func _apply_duration() -> void: 
    if duration <= 0:
        _stop_and_free_timer()
        return

    if !timer:
        timer = Timer.new()
        timer.one_shot = true
        add_child(timer)
        timer.timeout.connect(_on_duration_timeout)

    timer.wait_time = duration
    timer.start()


func refresh(durationOverride : float = -1.0) -> void:
    if durationOverride >= 0: duration = durationOverride
    _apply_duration()
    

func make_permanent() -> void:
    duration = 0
    _apply_duration()


func _stop_and_free_timer() -> void:
    if timer:
        timer.stop()
        timer.queue_free()
        timer = null


func _on_duration_timeout() -> void: queue_free()

