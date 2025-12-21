extends Window

var expression : Expression = Expression.new()

func _on_input_text_submitted(command : String) -> void:
	var error = expression.parse(command)
	if error != OK:
		print(expression.get_error_text())
		return
	
	var result = expression.execute([], self)
	if !expression.has_execute_failed():
		%console.text += "[color=fff]> [color=555]" + command + "\n"
		%console.text += "[color=fff]: " + str(result) + "\n"
		%input.text = ""


# commands for the console
func spawn_player(spawnPos : Vector3 = Vector3.ZERO, spawnRot : float = 0) -> String:
	await GameManager.spawn_player(spawnPos, spawnRot)
	return "spawned player"


func area_gen() -> String:
	GameManager.run_area_generation()
	return "generated areas"


func play_ui_sfx(sfx : String, pitch : float = 1.0) -> String: 
	AudioManager.play_ui_sfx(sfx, pitch)
	return "playing " + sfx

func play_talk_sfx(sfx : String, pitch : float = 1.0) -> String: 
	AudioManager.play_talk_sfx(sfx, pitch)
	return "playing " + sfx

func play_jingle(sfx : String, pitch : float = 1.0) -> String: 
	AudioManager.play_jingle(sfx, pitch)
	return "playing " + sfx

func change_flag(flag : String, val) -> String:
	GameFlags.set_flag(flag, val)
	return "set " + flag + " to " + str(val)

func set_player_speed(speed : float) -> String:
	GameManager.player.speed = speed
	return "set player speed to " + str(speed) 

func reset_player_speed() -> String:
	GameManager.player.speed = 8.0
	return "reset player speed to default"

func set_player_hp(hp : float) -> String:
	GameManager.player.healthComponent.health = hp
	return "player hp set to " + str(GameManager.player.stats.HP)