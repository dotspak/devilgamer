@tool
extends GPUParticles3D
class_name BloodSplatter

const DEF_FLOOR_HEIGHT : float = -0.5
const DEF_COLOR : Color = Color("8b2125b4")

@export var color : Color = DEF_COLOR :
	set(val):
		color = val
		var mainMat : ShaderMaterial = material_override
		mainMat.set_shader_parameter("color", color)

		if splat:
			var splatMat : ShaderMaterial = splat.material_override
			var splatColor : Color = color
			splatColor.v *= 0.5
			splatMat.set_shader_parameter("color", color)

@export_range(0, 1.0) var bloodAmount : float = 1.0 :
	set(val):
		bloodAmount = val
		amount_ratio = bloodAmount

@export var floorHeight : float = DEF_FLOOR_HEIGHT :
	set(val):
		floorHeight = val
		if particleFloor:
			particleFloor.position.y = floorHeight

@export_tool_button("Determine Floor Position", "Marker3D")
var floorButton : Callable = set_floor_pos

@onready var splat : GPUParticles3D = %bloodSplat
@onready var particleFloor : GPUParticlesCollisionBox3D = %floor
@onready var floorScanner : RayCast3D = %RayCast3D

func spawn(_bloodAmount : float = 1, _color : Color = DEF_COLOR, permanent : bool = false) -> void:
	emitting = false
	bloodAmount = _bloodAmount
	color = _color

	if !set_floor_pos():
		floorHeight = DEF_FLOOR_HEIGHT
	
	if !permanent:
		one_shot = true
		splat.finished.connect(queue_free)
	
	emitting = true


func set_floor_pos() -> bool:
	floorScanner.force_raycast_update()
	if floorScanner.is_colliding():
		var point : Vector3 = floorScanner.get_collision_point()
		point = self.to_local(point)
		floorHeight = point.y - particleFloor.size.y * 0.5
		return true
	
	printerr("Floor not detected for blood particles ", name)
	return false
