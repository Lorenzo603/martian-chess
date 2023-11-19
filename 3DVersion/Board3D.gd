extends Node3D

@export var autogenerate_board := true

@onready var tile_scene: PackedScene = preload("res://3DVersion/tile_3d.tscn")
@onready var pyr_big_scene: PackedScene = preload("res://3DVersion/pyramid_big.tscn")
@onready var pyr_medium_scene: PackedScene = preload("res://3DVersion/pyramid_medium.tscn")
@onready var pyr_small_scene: PackedScene = preload("res://3DVersion/pyramid_small.tscn")

func _ready():
	if autogenerate_board:
		_autogenerate_board()
		
func _autogenerate_board():
	for c in get_tree().get_nodes_in_group("testing"):
		c.queue_free()

	var tile_scale = Vector3(2.5, 1, 2.5)
	var start_x = 0
	var start_z = 0
	var white_tile = false
	for i in range(0, 8):
		white_tile = not white_tile
		for j in range(0, 4):
			var tile: MeshInstance3D = tile_scene.instantiate()
			if not white_tile:
				tile.tile_color = Color.BLACK
			white_tile = not white_tile
			add_child(tile)
			
			tile.set_meta("TileCoordX", i)
			tile.set_meta("TileCoordY", j)
			tile.add_to_group("tiles")
			tile.scale = tile_scale
			tile.global_position = Vector3(start_x + _get_canal_offset(i) + 1*i*tile_scale.x, 0, start_z - 1*j*tile_scale.z)
	
	_instantiate_piece(pyr_big_scene, [[7, 3], [7, 2], [6, 3], [0, 0], [0, 1], [1, 0]])
	_instantiate_piece(pyr_medium_scene, [[7, 1], [6, 2], [5, 3], [0, 2], [1, 1], [2, 0]])
	_instantiate_piece(pyr_small_scene, [[5, 2], [5, 1], [6, 1], [2, 1], [2, 2], [1, 2]])
	

func _get_canal_offset(x):
	return 0.0 if x < 4 else 0.25

func _instantiate_piece(piece_scene, coords_list):
	for coords in coords_list:
		var piece = piece_scene.instantiate()
		var tile = get_tile_by_coord(coords[0], coords[1])
		add_child(piece)
		tile.set_piece(piece)
		piece.starting_tile_x = coords[0]
		piece.starting_tile_y = coords[1]
		piece.starting_tile_ref = tile
		piece.global_position = tile.get_node("PieceClampPosition").global_position

func get_tile_by_coord(x, y):
	for t in get_tree().get_nodes_in_group("tiles"):
		if t.get_meta("TileCoordX") == x and t.get_meta("TileCoordY") == y:
			return t
	return null
