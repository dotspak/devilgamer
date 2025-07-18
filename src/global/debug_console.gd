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


func area_gen() -> String:
	GameManager.run_area_generation()
	return "generated areas"