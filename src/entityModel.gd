extends Node3D
class_name EntityModel

const EFFECT_MATERIAL : StandardMaterial3D = preload("res://shaders/entityEffects.tres")

@export var meshRoot : Node3D


func _ready() -> void:
    if meshRoot: apply_flash_material_to_meshes()

func apply_flash_material_to_meshes() -> void:
    for child in meshRoot.get_children():
        if child is MeshInstance3D:
            print("applied material")
            child.material_overlay = EFFECT_MATERIAL


func damage_flash() -> void:
    for child in meshRoot.get_children():
        if child is MeshInstance3D:
            var mat : StandardMaterial3D = child.material_overlay
            var tween : Tween = create_tween()
            var time : float = 0.1
            tween.tween_property(mat, "albedo_color:a", 1.0, time / 2)
            tween.tween_property(mat, "albedo_color:a", 0, time / 2)
