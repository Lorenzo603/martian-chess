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
		
	match game_mode:
		GameMode.TWO_PLAYER:
			return
		GameMode.RANDOM_AI:
			ai_move_random()
			return
		GameMode.SMART_AI:
			return
	
func ai_move_random():
	await get_tree().create_timer(1.0).timeout
	
	var next_move = _get_random_move()
	var moved_piece = _get_tile_by_coord(next_move["starting_tile_x"], next_move["starting_tile_y"]).piece
	var destination_tile = _get_tile_by_coord(next_move["destination_tile_x"], next_move["destination_tile_y"])
	
	var move_result = board.is_move_valid(next_move["starting_tile_x"], next_move["starting_tile_y"], 
		next_move["destination_tile_x"], next_move["destination_tile_y"]
	)
	SignalBus.piece_moved.emit(moved_piece, move_result, 
		next_move["destination_tile_x"], next_move["destination_tile_y"], 
		destination_tile)

func _get_random_move():
	var valid_moves = _get_valid_moves()
	var random_move = valid_moves[randi() % len(valid_moves)]
	return {
		"starting_tile_x": random_move["starting_tile_x"],
		"starting_tile_y": random_move["starting_tile_y"],
		"destination_tile_x": random_move["destination_tile_x"],
		"destination_tile_y": random_move["destination_tile_y"]
	}

func _get_valid_moves():
	var valid_moves = []
	var available_pieces = []
	# only looks at top side of board
	var board_state = board.board_state
	for i in range(0, 4):
			for j in range(0, 4):
				if board_state[i][j] != "":
					available_pieces.append(
						{
							"sx": i,
							"sy": j,
							"piece_type": board_state[i][j]
					})
	for p in available_pieces:
		valid_moves.append_array(_get_valid_moves_for_piece_coord(p))
		
	return valid_moves

func _get_valid_moves_for_piece_coord(piece_coord):
	var board_state = board.board_state
	var valid_moves = []
	match piece_coord["piece_type"]:
		"S": 
			for i in [-1, 1]:
				for j in [-1, 1]:
					var dx = piece_coord["sx"] + i
					var dy = piece_coord["sy"] + j
					if 0 <= dx and dx <= 7 and 0 <= dy and dy <= 3 \
						and board.is_piece_movement_valid("S", piece_coord["sx"], piece_coord["sy"], 
								dx, dy)[0]:
						valid_moves.append({
							"starting_tile_x": piece_coord["sx"],
							"starting_tile_y": piece_coord["sy"],
							"destination_tile_x": dx,
							"destination_tile_y": dy
						})
		"M": 
			for i in [-2, -1, 1, 2]:
				var dx = piece_coord["sx"] + i
				var dy = piece_coord["sy"]
				if 0 <= dx and dx <= 7 and 0 <= dy and dy <= 3 \
					and board.is_piece_movement_valid("M", piece_coord["sx"], piece_coord["sy"], 
							dx, dy)[0]:
					valid_moves.append({
						"starting_tile_x": piece_coord["sx"],
						"starting_tile_y": piece_coord["sy"],
						"destination_tile_x": dx,
						"destination_tile_y": dy
					})
			for j in [-2, -1, 1, 2]:
				var dx = piece_coord["sx"]
				var dy = piece_coord["sy"] + j
				if 0 <= dx and dx <= 7 and 0 <= dy and dy <= 3 \
					and board.is_piece_movement_valid("M", piece_coord["sx"], piece_coord["sy"], 
							dx, dy)[0]:
					valid_moves.append({
						"starting_tile_x": piece_coord["sx"],
						"starting_tile_y": piece_coord["sy"],
						"destination_tile_x": dx,
						"destination_tile_y": dy
					})
						
		"B": 
			"""
			for i in range(0, 8):
				var dx = i
				var dy = piece_coord["sy"]
				if dx != piece_coord["sx"] \
					and board.is_piece_movement_valid("B", piece_coord["sx"], piece_coord["sy"], 
							dx, dy)[0]:
					valid_moves.append({
						"starting_tile_x": piece_coord["sx"],
						"starting_tile_y": piece_coord["sy"],
						"destination_tile_x": dx,
						"destination_tile_y": dy
					})
			for j in range(0, 4):
				var dx = piece_coord["sx"]
				var dy = j
				if dy != piece_coord["sy"] \
					and board.is_piece_movement_valid("B", piece_coord["sx"], piece_coord["sy"], 
							dx, dy)[0]:
					valid_moves.append({
						"starting_tile_x": piece_coord["sx"],
						"starting_tile_y": piece_coord["sy"],
						"destination_tile_x": dx,
						"destination_tile_y": dy
					})
			"""	
			for i in range(0, 8):
				for j in range(0, 4):
					if not (i == piece_coord["sx"] and j == piece_coord["sy"]) \
						and board.is_piece_movement_valid("B", piece_coord["sx"], piece_coord["sy"], 
							i, j)[0]:
						valid_moves.append({
							"starting_tile_x": piece_coord["sx"],
							"starting_tile_y": piece_coord["sy"],
							"destination_tile_x": i,
							"destination_tile_y": j
						})
	return valid_moves
	
func _get_tile_by_coord(x, y):
	for t in board.get_children():
		if t.get_meta("TileCoordX") == x and t.get_meta("TileCoordY") == y:
			return t
	return null
