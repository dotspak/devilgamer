@icon("res://icons/audioManager.svg")
extends Node

@onready var bgmPlayer : AudioStreamPlayer = %BGM
var bgmVolume : float = 1.0
var bgmPitch : float = 1.0

var library : Dictionary[String, Dictionary]

func _ready(): load_sfx_library()
func load_sfx_library() -> void:
	for n : Node in get_children():
		if n.get_class() != "Node": continue

		library[n.name] = {}
		for sound in n.get_children():
			if !sound is AudioStreamPlayer: continue
			library[n.name][sound.name] = {}
			library[n.name][sound.name]["sound"] = sound
			library[n.name][sound.name]["pitch"] = sound.pitch_scale
	
	print("loaded all sounds successfully:\n", library)


func play_bgm(bgm : AudioStream, volume : float = 1.0, pitch : float = 1.0, fadeIn : float = 0.0, altPlayer : AudioStreamPlayer = null) -> void:
	if bgmPlayer : bgmPlayer.stop()
	bgmPlayer = %BGM if !altPlayer else altPlayer
	bgmPlayer.stream = bgm
	bgmPlayer.pitch_scale = pitch
	bgmVolume = volume
	bgmPitch = pitch
	bgmPlayer.volume_linear = 0
	await fade_bgm(fadeIn, false)


# fades in or out the bgm. assumes a bgm is currently playing, so should be used
# after play_bgm has already been triggered
func fade_bgm(duration : float = 1.0, fadeOut : bool = true) -> void:
	if !bgmPlayer: return
	var TW = create_tween()
	var val : Array = [bgmVolume, 0] if fadeOut else [0, bgmVolume] # 0 = start volume, 1 = end
	bgmPlayer.volume_linear = val[0]
	TW.tween_property(bgmPlayer, "volume_linear", val[1], duration).from(val[0])
	if !fadeOut: bgmPlayer.play()
	await TW.finished
	if fadeOut: bgmPlayer.stream_paused = true


# play a sound of a given category
func play_ui_sfx(sfx : String, pitch : float = 1.0) -> void: 
	if library["uiSounds"].has(sfx): play_sfx(sfx, library["uiSounds"], pitch)

func play_talk_sfx(sfx : String, pitch : float = 1.0, mood : String = "") -> void: 
	if library["talkSounds"].has(sfx): play_sfx(sfx, library["talkSounds"], pitch, mood)

func play_jingle(sfx : String, pitch : float = 1.0) -> void: 
	if library["jingles"].has(sfx): play_sfx(sfx, library["jingles"], pitch)


# plays a sound from a given sfx bank. Should only be called from the more specific helper functions
func play_sfx(sfx : String, bank : Dictionary, pitch : float, mood : String = "") -> void:
	if !bank.has(sfx):
		printerr("sound not found ", sfx, " in ", bank)
		return
	
	var sound : AudioStreamPlayer = bank[sfx]["sound"]
	var defaultPitch : float = bank[sfx]["pitch"]

	sound.pitch_scale = max(defaultPitch * pitch, 0.01)
	if sound is TalkObject: sound.talk_sound(mood)
	else: sound.play()


func set_lowpass(enable : bool = true) -> void: AudioServer.set_bus_effect_enabled(0, 0, enable)