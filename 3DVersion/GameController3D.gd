extends Node

const piece_big_scene = preload("res://Assets/Models/pyramid.glb")
const piece_medium_scene = preload("res://Assets/Sprites/PieceMedium.png")

@onready var board = get_node("../Board")

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
		var a=1
		# TODO change model
		# moved_piece.set_texture(piece_big_texture if promotion_piece == "B" else piece_medium_texture)
	destination_tile.set_piece(moved_piece)
	moved_piece.starting_tile_ref = destination_tile
	
	var clamp_position = destination_tile.get_node("PieceClampPosition").global_position
	moved_piece.global_position = clamp_position
	moved_piece.starting_tile_x = destination_tile_x
	moved_piece.starting_tile_y = destination_tile_y
	
	
func _highlight_move_tiles(starting_tile: MeshInstance3D, destination_tile: MeshInstance3D):
	#for tile in board.get_children():
	#	tile.modulate = Color(1, 1, 1)
	#starting_tile.modulate = Color(0, 1, 0.5)
	#destination_tile.modulate = Color(0, 1, 0.5)
	pass
