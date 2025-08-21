@tool
extends GPUParticles3D

@export var color : Color = Color("ff3d44b4") :
    set(val):
        color = val
        var mainMat : ShaderMaterial = material_override
        mainMat.set_shader_parameter("color", color)

        var splatMat : ShaderMaterial = splat.material_override
        var splatColor : Color = color
        splatColor.v *= 0.5
        splatMat.set_shader_parameter("color", color)

@export_range(0, 1.0) var bloodAmount : float = 1.0 :
    set(val):
        bloodAmount = val
        amount_ratio = bloodAmount
        splat.amount_ratio = bloodAmount

@export var floorHeight : float = -0.625 :
    set(val):
        floorHeight = val
        particleFloor.position.y = floorHeight


@onready var splat : GPUParticles3D = $bloodSplat
@onready var particleFloor : GPUParticlesCollisionBox3D = $floor