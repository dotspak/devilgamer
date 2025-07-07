extends Area3D
class_name WaterArea3D

@export var splash_effect : PackedScene = preload("res://scenes/particles/waterSplash.tscn")

func _ready() -> void: 
	body_entered.connect(_on_body_entered)


func water_splash(pos : Vector3) -> void:
	var splash : GPUParticles3D = splash_effect.instantiate()
	add_child(splash)
	splash.global_position = pos
	splash.finished.connect(splash.queue_free)
	splash.emitting = true

	
func get_water_color() -> Color:
	var plane : MeshInstance3D = get_parent()
	if plane and plane.material_override is ShaderMaterial:
		return plane.material_override.get_shader_parameter("color")
	return Color.ALICE_BLUE


func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D || body is RigidBody3D: 
		water_splash(body.global_position)
