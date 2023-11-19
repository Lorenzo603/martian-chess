extends Node

@onready var pyr_big_scene: PackedScene = preload("res://3DVersion/pyramid_big.tscn")
@onready var pyr_medium_scene: PackedScene = preload("res://3DVersion/pyramid_medium.tscn")

@onready var board3D = get_parent()

func _ready():
	SignalBus.piece_moved.connect(_on_piece_moved)
	
func _on_piece_moved(moved_piece, move_result, destination_tile_x, destination_tile_y,
	destination_tile):
	_highlight_move_tiles(moved_piece.starting_tile_ref, destination_tile)
	
	moved_piece.starting_tile_ref.set_piece(null)
	var has_captured = move_result[1]
	var promotion_piece = move_result[2]
	if has_captured:
		destination_tile.get_piece().queue_free()
	if promotion_piece != "":
		var new_promoted_piece = pyr_big_scene.instantiate() if promotion_piece == "B" else pyr_medium_scene.instantiate()
		board3D.add_child(new_promoted_piece)
		destination_tile.get_piece().queue_free()
		moved_piece.queue_free()
		moved_piece = new_promoted_piece
		
	destination_tile.set_piece(moved_piece)
	moved_piece.starting_tile_ref = destination_tile
	
	var clamp_position = destination_tile.get_node("PieceClampPosition").global_position
	moved_piece.global_position = clamp_position
	moved_piece.starting_tile_x = destination_tile_x
	moved_piece.starting_tile_y = destination_tile_y
	
	
func _highlight_move_tiles(starting_tile: MeshInstance3D, destination_tile: MeshInstance3D):
	for tile in get_tree().get_nodes_in_group("tiles"):
		tile.get_surface_override_material(0).albedo_color = tile.tile_color
	starting_tile.get_surface_override_material(0).albedo_color = Color(0, 1, 0.5)
	destination_tile.get_surface_override_material(0).albedo_color = Color(0, 1, 0.5)
