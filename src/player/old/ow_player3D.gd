extends CharacterBody3D
class_name OverworldPlayer3D

const MSENS : float = 0.02

@export_category("movement")
@export var rotateSpeed : float = 12
@export var walkSpeed : float = 10
@export var accel : float = 12
@export var deccel : float = 15

@onready var model : Node3D = $psxGirl
@onready var springArm : SpringArm3D = $SpringArm3D
@onready var animTree : AnimationTree = $AnimationTree

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var modernControl : bool = false
var resetCamera : bool = false
var moveInput : Vector2

func _physics_process(delta: float) -> void:
    if is_on_floor(): 
        if !resetCamera:
            handle_move_input(delta)
    else: 
        velocity.y -= gravity * delta

    if resetCamera: center_camera()
    move_and_slide()

func handle_move_input(delta : float) -> void:
    var vy : float = velocity.y
    velocity.y = 0
    moveInput = Input.get_vector("left", "right", "up", "down")
    var direction : Vector3 = Vector3(moveInput.x, 0, moveInput.y).rotated(Vector3.UP, springArm.rotation.y)

    # handles if there was any moveInput
    if moveInput != Vector2.ZERO:
        velocity = lerp(velocity, direction * walkSpeed, accel * delta)

        # rotate the model based on the velocity
        if velocity.x || velocity.z:
            animTree.set("parameters/conditions/idle", false)
            animTree.set("parameters/conditions/walking", true)
            model.rotation.y = lerp_angle(
                model.rotation.y, Vector2(direction.x, -direction.z).angle() + deg_to_rad(90), rotateSpeed * delta)
    else:
        # slow down the character
        animTree.set("parameters/conditions/idle", true)
        animTree.set("parameters/conditions/walking", false)
        velocity = lerp(velocity, Vector3.ZERO, deccel * delta)
        if (Vector2(velocity.x, velocity.z).length() < 0.2):
            velocity.x = 0
            velocity.z = 0

    velocity.y = vy

func _unhandled_input(event: InputEvent) -> void: camera_controls(event)
func camera_controls(event : InputEvent) -> void:
    # camera buttons
    if event is InputEvent:
        if event.is_action_released("center_camera"): resetCamera = true

        # handles mouse movement, if enabled
        if modernControl:
            if event is InputEventMouseMotion:
                springArm.rotation.x -= event.relative.y * MSENS
                springArm.rotation_degrees.x = clamp(springArm.rotation_degrees.x, -90, 30)
                springArm.rotation.y -= event.relative.x * MSENS

func center_camera() -> void:
    var y : float = deg_to_rad(model.rotation_degrees.y + 180)
    var final : Vector3 = Vector3(deg_to_rad(-20), y, 0)
    var diff : float = final.distance_to(springArm.rotation)
    springArm.rotation = lerp(springArm.rotation, final, 0.4)
    if diff <= 0.01: resetCamera = false