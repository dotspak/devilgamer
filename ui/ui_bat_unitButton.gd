extends Button
class_name UnitButton

@export var ratingGrad : GradientTexture1D
var units : Array

func _ready(): unSelected()

# sets up the info of the button based on the passed units
func setup(u : Array, nameOverride : String = "") -> void:
    units = u
    if nameOverride: %name.text = nameOverride
    else: %name.text = units[0].charSheet.name

    if units[0] is Enemy: %name.modulate = Color.SALMON
    else: %name.modulate = Color.LIGHT_GREEN

func selected() -> void:
    var TW : Tween = create_tween()
    TW.tween_property($shadow, "color", Color.SALMON, 0.04)
    TW.tween_property($shadow, "color", Color.DARK_RED,0.06)

func unSelected() -> void: create_tween().tween_property($shadow, "color", Color(0.1,0.1,0.1), 0.1)
