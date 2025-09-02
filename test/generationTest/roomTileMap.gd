@tool
extends TileMapLayer
class_name RoomTileMap

func _ready() -> void: tile_set = load("res://src/world/roomTileset.tres")