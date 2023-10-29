extends Node

signal score_changed(player, new_score)
signal game_ended

const MAX_PLAYERS = 2

var player_turn = 1

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

func update_player_turn():
	player_turn += 1
	if player_turn > MAX_PLAYERS:
		player_turn = 1

func is_piece_draggable(starting_tile_x, starting_tile_y):
	return (starting_tile_x > 3 and player_turn == 1) or (starting_tile_x <=3 and player_turn == 2)

func is_move_valid(starting_tile_x, starting_tile_y, destination_tile_x, destination_tile_y):
	print_debug(str(starting_tile_x) + "," + str(starting_tile_y) + "[" + board_state[starting_tile_x][starting_tile_y] + "]" +
		" --> " + str(destination_tile_x) + "," + str(destination_tile_y) + "[" + board_state[destination_tile_x][destination_tile_y] + "]")
	
	# cannot move piece to same position
	if starting_tile_x == destination_tile_x and starting_tile_y == destination_tile_y:
		return [false, false, ""]
	
	# cannot capture own piece
	var promotion_piece = _get_promotion_piece(starting_tile_x, starting_tile_y, destination_tile_x, destination_tile_y)
	if promotion_piece == "" \
		and (
			(destination_tile_x > 3 and player_turn == 1 and board_state[destination_tile_x][destination_tile_y] != "") \
			or (destination_tile_x <= 3 and player_turn == 2 and board_state[destination_tile_x][destination_tile_y] != "")
		):
		return [false, false, ""]
		
	# cannot "reject" move
	if previous_starting_tile_x == destination_tile_x and previous_starting_tile_y == destination_tile_y \
		and previous_destination_tile_x == starting_tile_x and previous_destination_tile_y == starting_tile_y:
		return [false, false, ""]
	
	var current_piece_type = board_state[starting_tile_x][starting_tile_y]
	var is_movement_valid = _is_piece_movement_valid(current_piece_type, starting_tile_x, starting_tile_y, destination_tile_x, destination_tile_y)
	
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
			game_ended.emit()
		else:
			update_player_turn()
	return [is_movement_valid, has_captured, promotion_piece]
	
func _calculate_score(captured_pieces_list):
	return captured_pieces_list.reduce(func(accum, piece_type): return accum + piece_value_map[piece_type], 0)
	
func _is_piece_movement_valid(current_piece_type, starting_tile_x, starting_tile_y, destination_tile_x, destination_tile_y):
	match current_piece_type:
		"S":
			return (destination_tile_x == starting_tile_x + 1 and destination_tile_y == starting_tile_y + 1) \
				or (destination_tile_x == starting_tile_x - 1 and destination_tile_y == starting_tile_y - 1) \
				or (destination_tile_x == starting_tile_x + 1 and destination_tile_y == starting_tile_y - 1) \
				or (destination_tile_x == starting_tile_x - 1 and destination_tile_y == starting_tile_y + 1)
		"M":
			return ((destination_tile_x == starting_tile_x + 1 or (destination_tile_x == starting_tile_x + 2 and board_state[starting_tile_x + 1][starting_tile_y] == "")) and destination_tile_y == starting_tile_y) \
				or ((destination_tile_x == starting_tile_x - 1 or (destination_tile_x == starting_tile_x - 2 and board_state[starting_tile_x - 1][starting_tile_y] == "")) and destination_tile_y == starting_tile_y) \
				or ((destination_tile_y == starting_tile_y + 1 or (destination_tile_y == starting_tile_y + 2 and board_state[starting_tile_x][starting_tile_y + 1] == "")) and destination_tile_x == starting_tile_x) \
				or ((destination_tile_y == starting_tile_y - 1 or (destination_tile_y == starting_tile_y - 2 and board_state[starting_tile_x][starting_tile_y - 1] == "")) and destination_tile_x == starting_tile_x)
		"B":
			if abs(starting_tile_x - destination_tile_x) == abs(starting_tile_y - destination_tile_y):
				for num_gaps in range(1, abs(starting_tile_x - destination_tile_x)):
					var i = starting_tile_x + num_gaps * (1 if destination_tile_x > starting_tile_x else -1)
					var j = starting_tile_y + num_gaps * (1 if destination_tile_y > starting_tile_y else -1)
					if board_state[i][j] != "":
						return false

			if starting_tile_x == destination_tile_x:
				for i in range(min(starting_tile_y, destination_tile_y) + 1, max(starting_tile_y, destination_tile_y)):
					if board_state[starting_tile_x][i] != "":
						return false
			if starting_tile_y == destination_tile_y:
				for i in range(min(starting_tile_x, destination_tile_x) + 1, max(starting_tile_x, destination_tile_x)):
					if board_state[i][starting_tile_y] != "":
						return false
			
			return true

	return false

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
