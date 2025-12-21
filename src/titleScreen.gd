extends Control

enum TitleStates {START, FILE_SELECT}
var STATE = TitleStates.START

@onready var music : AudioStreamPlayer = %music
@onready var startPage : Control = %startPage
@onready var filePage : Control = %filePage
@onready var titleOptions : Control = %titleOptions
@onready var titleLabel : RichTextLabel = %title

var inputAllowed : bool = true
var hasFile : bool = false :
	set(val):
		hasFile = val
		if hasFile:
			%continue.text = "continue"
			%reset.disabled = false
			make_file_alive()
		else:
			%continue.text = "create"
			%reset.disabled = true
			make_file_dead()


const TITLE_TEXT = "[font_size=48][shake][bgcolor=000]> devilgamer"
var dashOn : bool = false

func _ready():
	animate_title()
	startPage.show()
	filePage.hide()

	if hasFile: make_file_alive()
	else: make_file_dead()

	set_input(false)
	AudioManager.play_bgm(music.stream, 1, 1, 0, music)
	await start_anim()
	set_input(true)


func _unhandled_input(_event: InputEvent) -> void:
	if STATE == TitleStates.START:
		if Input.is_anything_pressed():
			STATE = TitleStates.FILE_SELECT

			set_input(false)
			await start_to_file()
			set_input(true)
	if STATE == TitleStates.FILE_SELECT:
		if Input.is_action_just_pressed("ui_cancel"):
			STATE = TitleStates.START

			set_input(false)
			await file_to_start()
			set_input(true)


func start_anim() -> void:
	var TW : Tween = create_tween().set_parallel().set_trans(Tween.TRANS_QUAD)
	var titlePos : float = titleLabel.position.y
	var marginContainer : MarginContainer = $MarginContainer
	var mPos : float = marginContainer.position.y
	var time : float = 1.0

	TW.tween_property(titleLabel, "position:y", titlePos, time).from(titlePos - 40)
	TW.tween_property(titleLabel, "modulate:a", 1.0, time).from(0)
	TW.tween_property(marginContainer, "position:y", mPos, time).from(mPos + 40)
	TW.tween_property(marginContainer, "modulate:a", 1.0, time).from(0)
	await TW.finished


func start_to_file() -> void:
	AudioManager.play_ui_sfx("confirm")

	var TW : Tween = create_tween().set_parallel().set_trans(Tween.TRANS_QUAD)
	var filePos : float = filePage.position.y
	var startPos : float = startPage.position.y

	filePage.show()
	TW.tween_property(filePage, "position:y", filePos, 0.6).from(filePos + 40)
	TW.tween_property(filePage, "modulate:a", 1.0, 0.6).from(0)

	TW.tween_property(startPage, "position:y", startPos - 40, 0.6).from(startPos)
	TW.tween_property(startPage, "modulate:a", 0, 0.6)

	await TW.finished
	titleOptions.get_child(0).grab_focus()
	startPage.hide()
	startPage.position.y = startPos


func animate_title() -> void:
	dashOn = !dashOn
	if dashOn: titleLabel.text = TITLE_TEXT + "_"
	else: titleLabel.text = TITLE_TEXT + "[color=000]_"


func file_to_start() -> void:
	AudioManager.play_ui_sfx("cancel")

	titleOptions.get_child(0).release_focus()
	titleOptions.get_child(1).release_focus()
	titleOptions.get_child(2).release_focus()
	
	var TW : Tween = create_tween().set_parallel().set_trans(Tween.TRANS_QUAD)
	var filePos : float = filePage.position.y
	var startPos : float = startPage.position.y

	startPage.show()
	TW.tween_property(startPage, "position:y", startPos, 0.6).from(startPos + 40)
	TW.tween_property(startPage, "modulate:a", 1.0, 0.6).from(0)

	TW.tween_property(filePage, "position:y", filePos - 40, 0.6).from(filePos)
	TW.tween_property(filePage, "modulate:a", 0, 0.6)

	await TW.finished
	filePage.hide()
	filePage.position.y = filePos


func create_file(time : float = 0.3) -> void:
	set_input(false)
	var pitch : float = 0.3
	var pitchTW : Tween = create_tween()
	pitchTW.tween_property(music, "pitch_scale", pitch, time * 0.2).from(1.0)
	await GameManager.play_static(time)

	pitchTW.kill()
	pitchTW = create_tween()
	pitchTW.tween_property(music, "pitch_scale", 1.0, time * 0.2).from(pitch)


func new_game() -> void:
	await create_file(1.0)
	GameManager.load_terminal("intro")
	queue_free()


func end_title() -> void:
	set_input(false)
	titleOptions.get_child(0).release_focus()
	titleOptions.get_child(1).release_focus()
	titleOptions.get_child(2).release_focus()
	
	AudioManager.fade_bgm(1.8)
	await GameManager.fadeout_screen(2.0, Color.BLACK)

	GameManager.player.un_freeze()
	GameManager.player.show()
	hide()

	GameManager.areaLoaded.connect(queue_free)
	GameManager.load_area(GameManager.startingArea, "", Color.BLACK)
	

func set_input(val) -> void:
	set_process_input(val)
	set_process_unhandled_input(val)


func make_file_dead() -> void:
	%deadLabel.show()
	%fileContainer.hide()


func make_file_alive() -> void:
	%fileContainer.show()
	%deadLabel.hide()


# button signal connections
func button_focus() -> void:
	AudioManager.play_ui_sfx("cursor", randf_range(0.9, 1.1))


func _on_continue_pressed() -> void:
	GameManager.run_area_generation()
	if hasFile:
		AudioManager.play_ui_sfx("confirm")
		end_title()
	else:
		hasFile = true
		new_game()
		

func _on_reset_pressed() -> void:
	if hasFile:
		hasFile = false
		await create_file()


func _on_options_pressed() -> void:
	AudioManager.play_ui_sfx("confirm")

