extends Node3D

@export var autogenerate_board := true

@onready var tile_scene: PackedScene = preload("res://3DVersion/tile_3d.tscn")

func _ready():
	if autogenerate_board:
		_autogenerate_board()
		
func _autogenerate_board():
	for c in get_children():
		c.queue_free()
	
	var start_x = 0
	var start_z = 0
	var white_tile = false
	for i in range(0, 8):
		white_tile = not white_tile
		for j in range(0, 4):
			var tile: MeshInstance3D = tile_scene.instantiate()
			tile.position = Vector3(start_x + 1*i, 0, start_z - 1*j)
			if not white_tile:
				tile.tile_color = Color.BLACK
			add_child(tile)
			white_tile = not white_tile
			
