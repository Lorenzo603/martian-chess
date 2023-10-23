extends Node

const MAX_PLAYERS = 2

var player_turn = 1

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


func is_move_valid(starting_tile_x, starting_tile_y, destination_tile_x, destination_tile_y):
	print_debug(str(starting_tile_x) + "," + str(starting_tile_y) + "[" + board_state[starting_tile_x][starting_tile_y] + "]" +
		" --> " + str(destination_tile_x) + "," + str(destination_tile_y) + "[" + board_state[destination_tile_x][destination_tile_y] + "]")
	
	# cannot move piece to same position
	if starting_tile_x == destination_tile_x and starting_tile_y == destination_tile_y:
		return false
	
	# cannot capture own piece
	# TODO: Exception for when promoting
	if (destination_tile_x > 3 and player_turn == 1 and board_state[destination_tile_x][destination_tile_y] != "") \
		or (destination_tile_x <= 3 and player_turn == 2 and board_state[destination_tile_x][destination_tile_y] != ""):
		return false
	
	var current_piece_type = board_state[starting_tile_x][starting_tile_y]
	var is_movement_valid = _is_piece_movement_valid(current_piece_type, starting_tile_x, starting_tile_y, destination_tile_x, destination_tile_y)
	print_debug("is_movement_valid: " + str(is_movement_valid))
	if is_movement_valid:
		board_state[starting_tile_x][starting_tile_y] = ""
		board_state[destination_tile_x][destination_tile_y] = current_piece_type
	return is_movement_valid
	
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
