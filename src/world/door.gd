@icon("res://icons/spacerIcon.png")
extends Node3D
class_name DoorInstance

@export var roomA : Node3D
@export var roomB : Node3D

@export_group("Node references")
@export var wall : MeshInstance3D
@export var space_a : Area3D
@export var space_b : Area3D
@export var entryA : Node3D
@export var entryB : Node3D


func _ready():
	set_shadow_color(Color.BLACK)
	space_a.body_entered.connect(enter_space_a)
	space_b.body_entered.connect(enter_space_b)
	

func enter_space_a(body : Node3D) -> void: 
	if body is OWPlayer: 
		print("entered space a")
		if roomA is RoomInstance: roomA.enter_room()
		if roomB is RoomInstance: roomB.exit_room()


func enter_space_b(body : Node3D) -> void: 
	if body is OWPlayer: 
		print("entered space b")
		if roomB is RoomInstance: roomB.enter_room()
		if roomA is RoomInstance: roomA.exit_room()


func set_shadow_color(color : Color) -> void: wall.get_active_material(0).albedo_color = color