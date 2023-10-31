extends Node

signal score_changed(player, new_score)
signal game_ended

const MAX_PLAYERS = 2

enum GameMode {TWO_PLAYER, RANDOM_AI, HIGH_SCORE_AI, MINMAX_AI}
@export var game_mode: GameMode = GameMode.TWO_PLAYER

var player_turn = 1
var game_over = false

# row index is player index (player_turn - 1)
var captured_pieces = [
	[],
	[]
]

const piece_value_map = {
	"S": 1,
	"M": 2,
	"B": 3,
}

var board_state = [
	["B", "B", "M", ""],
	["B", "M", "S", ""],
	["M", "S", "S", ""],
	["", "", "", ""],
	
	["", "", "", ""],
	["", "S", "S", "M"],
	["", "S", "M", "B"],
	["", "M", "B", "B"],
]

var previous_starting_tile_x = 0
var previous_starting_tile_y = 0
var previous_destination_tile_x = 0
var previous_destination_tile_y = 0

func _ready():
	SignalBus.end_turn.connect(_on_end_turn)

func update_player_turn():
	player_turn += 1
	if player_turn > MAX_PLAYERS:
		player_turn = 1

func is_piece_draggable(starting_tile_x, starting_tile_y):
	return not game_over and \
		(
			(starting_tile_x > 3 and player_turn == 1) 
			or (starting_tile_x <=3 and player_turn == 2 and game_mode == GameMode.TWO_PLAYER)
		)

func is_move_valid(starting_tile_x, starting_tile_y, destination_tile_x, destination_tile_y):
	print_debug(str(starting_tile_x) + "," + str(starting_tile_y) + "[" + board_state[starting_tile_x][starting_tile_y] + "]" +
		" --> " + str(destination_tile_x) + "," + str(destination_tile_y) + "[" + board_state[destination_tile_x][destination_tile_y] + "]")	
	
	var current_piece_type = board_state[starting_tile_x][starting_tile_y]
	var is_movement_valid_result = is_piece_movement_valid(current_piece_type, starting_tile_x, starting_tile_y, destination_tile_x, destination_tile_y)
	var is_movement_valid = is_movement_valid_result[0]
	var promotion_piece = is_movement_valid_result[1]
	
	var has_captured = false
	if is_movement_valid:
		# capture piece
		if board_state[destination_tile_x][destination_tile_y] != "":
			captured_pieces[player_turn - 1].append(board_state[destination_tile_x][destination_tile_y])
			has_captured = true
			score_changed.emit(player_turn, _calculate_score(captured_pieces[player_turn - 1]))
		board_state[starting_tile_x][starting_tile_y] = ""
		board_state[destination_tile_x][destination_tile_y] = current_piece_type if promotion_piece == "" else promotion_piece
		previous_starting_tile_x = starting_tile_x 
		previous_starting_tile_y = starting_tile_y
		previous_destination_tile_x = destination_tile_x
		previous_destination_tile_y = destination_tile_y
		if is_game_ended():
			game_over = true
			game_ended.emit()
		else:
			update_player_turn()
	return [is_movement_valid, has_captured, promotion_piece]
	
func _calculate_score(captured_pieces_list):
	return captured_pieces_list.reduce(func(accum, piece_type): return accum + piece_value_map[piece_type], 0)
	
func is_piece_movement_valid(current_piece_type, starting_tile_x, starting_tile_y, destination_tile_x, destination_tile_y):
	# cannot move piece to same position
	if starting_tile_x == destination_tile_x and starting_tile_y == destination_tile_y:
		return [false, ""]
	
	# cannot capture own piece
	var promotion_piece = _get_promotion_piece(starting_tile_x, starting_tile_y, destination_tile_x, destination_tile_y)
	if promotion_piece == "" \
		and (
			(destination_tile_x > 3 and player_turn == 1 and board_state[destination_tile_x][destination_tile_y] != "") \
			or (destination_tile_x <= 3 and player_turn == 2 and board_state[destination_tile_x][destination_tile_y] != "")
		):
		return [false, ""]
	
	# cannot "reject" move
	if previous_starting_tile_x == destination_tile_x and previous_starting_tile_y == destination_tile_y \
		and previous_destination_tile_x == starting_tile_x and previous_destination_tile_y == starting_tile_y:
		return [false, ""]
	
	match current_piece_type:
		"S":
			return [(destination_tile_x == starting_tile_x + 1 and destination_tile_y == starting_tile_y + 1) \
				or (destination_tile_x == starting_tile_x - 1 and destination_tile_y == starting_tile_y - 1) \
				or (destination_tile_x == starting_tile_x + 1 and destination_tile_y == starting_tile_y - 1) \
				or (destination_tile_x == starting_tile_x - 1 and destination_tile_y == starting_tile_y + 1), promotion_piece]
		"M":
			return [((destination_tile_x == starting_tile_x + 1 or (destination_tile_x == starting_tile_x + 2 and board_state[starting_tile_x + 1][starting_tile_y] == "")) and destination_tile_y == starting_tile_y) \
				or ((destination_tile_x == starting_tile_x - 1 or (destination_tile_x == starting_tile_x - 2 and board_state[starting_tile_x - 1][starting_tile_y] == "")) and destination_tile_y == starting_tile_y) \
				or ((destination_tile_y == starting_tile_y + 1 or (destination_tile_y == starting_tile_y + 2 and board_state[starting_tile_x][starting_tile_y + 1] == "")) and destination_tile_x == starting_tile_x) \
				or ((destination_tile_y == starting_tile_y - 1 or (destination_tile_y == starting_tile_y - 2 and board_state[starting_tile_x][starting_tile_y - 1] == "")) and destination_tile_x == starting_tile_x), promotion_piece]
		"B":
			if abs(starting_tile_x - destination_tile_x) == abs(starting_tile_y - destination_tile_y):
				for num_gaps in range(1, abs(starting_tile_x - destination_tile_x)):
					var i = starting_tile_x + num_gaps * (1 if destination_tile_x > starting_tile_x else -1)
					var j = starting_tile_y + num_gaps * (1 if destination_tile_y > starting_tile_y else -1)
					if board_state[i][j] != "":
						return [false, promotion_piece]
				return [true, promotion_piece]

			if starting_tile_x == destination_tile_x:
				for i in range(min(starting_tile_y, destination_tile_y) + 1, max(starting_tile_y, destination_tile_y)):
					if board_state[starting_tile_x][i] != "":
						return [false, promotion_piece]
				return [true, promotion_piece]
			
			if starting_tile_y == destination_tile_y:
				for i in range(min(starting_tile_x, destination_tile_x) + 1, max(starting_tile_x, destination_tile_x)):
					if board_state[i][starting_tile_y] != "":
						return [false, promotion_piece]
				return [true, promotion_piece]
			
			return [false, promotion_piece]

	return [false, promotion_piece]

# If you have no Queens, you can create one by moving a Drone into a Pawn’s space (or vice versa)
# and merging them. Similarly, if you control no Drones, you can make one by merging two of your Pawns.
func _get_promotion_piece(starting_tile_x, starting_tile_y, destination_tile_x, destination_tile_y):
	var num_pieces_map = _get_num_pieces()
	if num_pieces_map["B"] == 0 and \
		((board_state[starting_tile_x][starting_tile_y] == "S" and board_state[destination_tile_x][destination_tile_y] == "M")
		or (board_state[starting_tile_x][starting_tile_y] == "M" and board_state[destination_tile_x][destination_tile_y] == "S")):
		return "B"
	if num_pieces_map["M"] == 0 and \
		(board_state[starting_tile_x][starting_tile_y] == "S" and board_state[destination_tile_x][destination_tile_y] == "S"):
		return "M"
	return ""

func _get_num_pieces():
	var num_pieces_map = {
		"": 0,
		"S": 0,
		"M": 0,
		"B": 0,
	}
	var starting_row = 4 if player_turn == 1 else 0
	var ending_row = 8 if player_turn == 1 else 4
	for i in range(starting_row, ending_row):
		for j in range(0, 4):
			num_pieces_map[board_state[i][j]] += 1 
	return num_pieces_map

func is_game_ended():
	if player_turn == 2:
		for i in range(0, 4):
			for j in range(0, 4):
				if board_state[i][j] != "":
					return false
	else:
		for i in range(4, 8):
			for j in range(0, 4):
				if board_state[i][j] != "":
					return false
	return true

func _on_end_turn():
	if game_over:
		return
	
	var next_move = null
	match game_mode:
		GameMode.TWO_PLAYER:
			return
		GameMode.RANDOM_AI:
			await get_tree().create_timer(1.0).timeout
			next_move = MartianChessEngine.get_random_move()
		GameMode.HIGH_SCORE_AI:
			await get_tree().create_timer(1.0).timeout
			next_move = MartianChessEngine.get_high_score_move()
		GameMode.MINMAX_AI:
			await get_tree().create_timer(0.5).timeout
			next_move = await MartianChessEngine.get_best_move()
	
	var moved_piece = _get_tile_by_coord(next_move["starting_tile_x"], next_move["starting_tile_y"]).piece
	var destination_tile = _get_tile_by_coord(next_move["destination_tile_x"], next_move["destination_tile_y"])
	
	var move_result = is_move_valid(next_move["starting_tile_x"], next_move["starting_tile_y"], 
		next_move["destination_tile_x"], next_move["destination_tile_y"]
	)
	SignalBus.piece_moved.emit(moved_piece, move_result, 
		next_move["destination_tile_x"], next_move["destination_tile_y"], 
		destination_tile)

func _get_tile_by_coord(x, y):
	for t in get_children():
		if t.get_meta("TileCoordX") == x and t.get_meta("TileCoordY") == y:
			return t
	return null
