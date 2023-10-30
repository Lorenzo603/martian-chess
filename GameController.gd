extends Node

const piece_big_texture = preload("res://Assets/Sprites/PieceBig.png")
const piece_medium_texture = preload("res://Assets/Sprites/PieceMedium.png")

enum GameMode {TWO_PLAYER, RANDOM_AI, SMART_AI}
@export var game_mode: GameMode = GameMode.TWO_PLAYER

@onready var board = get_node("../Board")

# TODO: player goes second

func _ready():
	SignalBus.piece_moved.connect(_on_piece_moved)
	SignalBus.end_turn.connect(_on_end_turn)
	
func _on_piece_moved(moved_piece, move_result, destination_tile_x, destination_tile_y,
	overlapping_tile):
	moved_piece.starting_tile_ref.set_piece(null)
	var has_captured = move_result[1]
	var promotion_piece = move_result[2]
	if has_captured:
		overlapping_tile.get_piece().queue_free()
	if promotion_piece != "":
		moved_piece.set_texture(piece_big_texture if promotion_piece == "B" else piece_medium_texture)
	overlapping_tile.set_piece(moved_piece)
	moved_piece.starting_tile_ref = overlapping_tile
	
	var clamp_position = overlapping_tile.get_node("PieceClampPosition").global_position
	moved_piece.global_position = clamp_position
	moved_piece.starting_tile_x = destination_tile_x
	moved_piece.starting_tile_y = destination_tile_y
	
func _on_end_turn():
	if board.game_over:
		return
	
	var next_move = null
	match game_mode:
		GameMode.TWO_PLAYER:
			return
		GameMode.RANDOM_AI:
			await get_tree().create_timer(1.0).timeout
			next_move = _get_random_move()
		GameMode.SMART_AI:
			return
	
	var moved_piece = _get_tile_by_coord(next_move["starting_tile_x"], next_move["starting_tile_y"]).piece
	var destination_tile = _get_tile_by_coord(next_move["destination_tile_x"], next_move["destination_tile_y"])
	
	var move_result = board.is_move_valid(next_move["starting_tile_x"], next_move["starting_tile_y"], 
		next_move["destination_tile_x"], next_move["destination_tile_y"]
	)
	SignalBus.piece_moved.emit(moved_piece, move_result, 
		next_move["destination_tile_x"], next_move["destination_tile_y"], 
		destination_tile)


func _get_random_move():
	var legal_moves = MartianChessEngine.get_legal_moves()
	var random_move = legal_moves[randi() % len(legal_moves)]
	return {
		"starting_tile_x": random_move["starting_tile_x"],
		"starting_tile_y": random_move["starting_tile_y"],
		"destination_tile_x": random_move["destination_tile_x"],
		"destination_tile_y": random_move["destination_tile_y"]
	}


func _get_tile_by_coord(x, y):
	for t in board.get_children():
		if t.get_meta("TileCoordX") == x and t.get_meta("TileCoordY") == y:
			return t
	return null
