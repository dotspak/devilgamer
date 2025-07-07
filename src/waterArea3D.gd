extends Area3D
class_name WaterArea3D

var underPlayer : OWPlayer
var headWasUnder : bool = false

@export var splash_effect : PackedScene = preload("res://scenes/particles/waterSplash.tscn")

func _ready() -> void: 
	body_entered.connect(_on_body_entered)

func _process(_delta: float) -> void:
	if underPlayer:
		if headWasUnder:
			if !underPlayer.is_head_underwater(self):
				GameManager.handle_water_exit()
				headWasUnder = false
				if !underPlayer.is_underwater(self):
					underPlayer = null
		else:
			if underPlayer.is_head_underwater(self):
				GameManager.handle_water_change(get_water_color())
				headWasUnder = true
			
func get_water_color() -> Color:
	var plane : MeshInstance3D = get_parent()
	if plane and plane.material_override is ShaderMaterial:
		return plane.material_override.get_shader_parameter("color")
	return Color.ALICE_BLUE

func _on_body_entered(body: Node3D) -> void:
	if body is OWPlayer: underPlayer = body

	var splash : GPUParticles3D = splash_effect.instantiate()
	var pos : Vector3 = body.global_position

	add_child(splash)
	splash.global_position = pos
	splash.finished.connect(splash.queue_free)
	splash.emitting = true
