# give this node a reference to a CharacterBody3D and it will move the node around randomly
extends Node

@export var characterBody : CharacterBody3D

@export var move_range : float = 2.0         # Max distance from starting point
@export var move_speed : float = 5.0         # Movement speed
@export var wait_time : float = 0.1          # How long to wait at destination

var origin_position : Vector3
var target_position : Vector3
var wait_timer : float = 0.0

func _ready():
	origin_position = characterBody.global_position
	_set_new_target()

func _physics_process(delta: float) -> void:
	if characterBody.global_position.distance_to(target_position) > 0.1:
		var direction = (target_position - characterBody.global_position).normalized()
		characterBody.velocity = direction * move_speed
	else:
		characterBody.velocity = Vector3.ZERO
		wait_timer -= delta
		if wait_timer <= 0.0:
			_set_new_target()

	characterBody.move_and_slide()
	
func _set_new_target():
	var random_x = randf_range(-move_range, move_range)
	var random_z = randf_range(-move_range, move_range)
	target_position = origin_position + Vector3(random_x, 0, random_z)
	wait_timer = wait_time
