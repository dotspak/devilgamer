@tool
@icon("res://icons/talkObject.png")
extends AudioStreamPlayer
class_name TalkObject

var test : Dictionary[String, TalkObject]

@export_tool_button("Test Sound") var button = func() -> void:
    talk_sound("")
@export var talkSounds : Array[AudioStream] = []
@export var pitchRange : Vector2 = Vector2(0.85, 1.15)
var moods : Dictionary[String, TalkObject]

func _ready():
    for n in get_children():
        if n is TalkObject:
            moods[n.name] = n


func talk_sound(mood : String = "") -> void:
    if moods.has(mood):
        moods[mood].talk_sound(mood)
    else:
        stream = talkSounds.pick_random()
        pitch_scale = randf_range(pitchRange.x, pitchRange.y)
        play()