@tool
extends Node3D

@export var scrollSpeed : float = 2
@export var segmentHeight : float = 20.0

var segments : Array[MeshInstance3D] = []

func _ready() -> void:
    for n : MeshInstance3D in get_children():
        segments.append(n)

func _process(delta):
    for s : MeshInstance3D in segments:
        s.translate(Vector3.UP * scrollSpeed * delta)
        if s.position.y >= segmentHeight:
            var lowestY : float = get_lowest_seg_y()
            s.position.y = lowestY - segmentHeight


func get_lowest_seg_y() -> float:
    var lowestY : float = segments[0].position.y
    for s in segments:
        if s.position.y < lowestY:
            lowestY = s.position.y
    return lowestY