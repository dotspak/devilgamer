extends Node
class_name EntityModelController

const EFFECT_MATERIAL : StandardMaterial3D = preload("res://shaders/entityEffects.tres")
const DEATH_MATERIAL : StandardMaterial3D = preload("res://shaders/entityDeathEffect.tres")

@export var roots : Array[Node3D]

var meshes : Array[MeshInstance3D]

signal deathFinished
signal startedDeathAnim

func _ready() -> void:
	if !roots.is_empty():
		populate_meshes()
		apply_flash_material_to_meshes()


func populate_meshes() -> void:
	for node : Node3D in roots:
		for child in node.get_children():
			if child is MeshInstance3D:
				meshes.append(child)


func apply_flash_material_to_meshes() -> void:
	for mesh : MeshInstance3D in meshes:
		print("applied material")
		mesh.material_overlay = EFFECT_MATERIAL.duplicate()


func damage_flash() -> void:
	for mesh : MeshInstance3D in meshes:
		var mat : StandardMaterial3D = mesh.material_overlay
		var tween : Tween = create_tween()
		var time : float = 0.1
		tween.tween_property(mat, "albedo_color:a", 1.0, time / 2)
		tween.tween_property(mat, "albedo_color:a", 0, time / 2)


func create_death_effect() -> void:
	var deathNode : Node3D = Node3D.new()
	var tween : Tween = create_tween().set_parallel()
	var time : float = 0.6 
	var parent : Node = get_parent()

	parent.remove_child(self)
	parent.add_sibling(deathNode)
	parent.add_sibling(self)
	deathNode.show()
	deathNode.global_transform = parent.global_transform
	
	startedDeathAnim.emit()

	for mesh : MeshInstance3D in meshes:
		var copy : MeshInstance3D = mesh.duplicate()
		deathNode.add_child(copy)
		copy.material_override = DEATH_MATERIAL.duplicate()
		copy.material_overlay = null

		var mat : StandardMaterial3D = copy.material_override
		tween.tween_property(mat, "albedo_color:a", 0, time).from(1.0)
		#tween.tween_property(mat, "distance_fade_max_distance", 30, time).from(0)

	if tween.is_running(): await tween.finished
	
	print("death animation finished")
	tween.kill()
	deathNode.queue_free()
	deathFinished.emit()
