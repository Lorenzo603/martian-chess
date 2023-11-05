extends Node

signal minimax_tree_completed

const STARTING_TILE_X = 0
const STARTING_TILE_Y = 1
const DESTINATION_TILE_X = 2
const DESTINATION_TILE_Y = 3
const STARTING_PIECE = 4
const DESTINATION_PIECE = 5
const PROMOTION_PIECE = 6
const SCORE = 7

const PIECE_COORD_STARTING_X = 0
const PIECE_COORD_STARTING_Y = 1
const PIECE_COORD_PIECE_TYPE = 2

		
const piece_strength_map = {
	"": 0,
	
	# Player 1
	"S": 1,
	"M": 2,
	"B": 3,
	
}

var board_ref = null

var best_move = null
var previous_moves = []
var previous_num_pieces_maps = []

var mutex: Mutex
var semaphore: Semaphore
var thread: Thread
var exit_thread := false

func _ready():
	mutex = Mutex.new()
	semaphore = Semaphore.new()
	exit_thread = false

	thread = Thread.new()
	thread.start(_minimax_calculation_thread)

func _minimax_calculation_thread():
	Thread.set_thread_safety_checks_enabled(false)
	while true:
		semaphore.wait() # Wait until posted.

		mutex.lock()
		var should_exit = exit_thread # Protect with Mutex.
		mutex.unlock()

		if should_exit:
			break

		print_debug("Calculating Minimax tree...")
		mutex.lock()
		best_move = _calculate_best_move()
		mutex.unlock()
		print_debug("Calculating Minimax tree Completed!")
		minimax_tree_completed.emit()
		
func get_best_move(board):
	board_ref = board
	semaphore.post()
	await minimax_tree_completed
	if best_move == null:
		print_debug("No best move found, returning best high score")
		best_move = get_high_score_move(board_ref)
	return best_move
	
func _calculate_best_move():
	var best_value = INF # it is INF because we are loking for the best AI move, otherwise it would be -INF
	var bestMove = null
	previous_moves.clear()
	previous_num_pieces_maps.clear()
	var board_state = board_ref.board_state.duplicate(true)
	var depth = 4

	var num_pieces_map = get_num_pieces(board_state, 2)
	var initial_previous_move = [board_ref.previous_starting_tile_x, board_ref.previous_starting_tile_y, 
			board_ref.previous_destination_tile_x, board_ref.previous_destination_tile_y]
	var legal_moves = get_legal_moves(board_state, 2, initial_previous_move, num_pieces_map)
	# SortMoves(board, pseudoLegalMoves);

	for move in legal_moves:
		_make_move(board_state, move, 2)
		var cumulative_value = -piece_strength_map[move[DESTINATION_PIECE]]
		var value = _minimax(board_state, previous_num_pieces_maps.back(), move,
			depth, -INF, INF, true, cumulative_value)
		_unmake_move(board_state)
		
		# TODO save all best moves and pick a random one
		if value <= best_value: # it is <= because we are loking for the best AI move, otherwise it would be >=
			best_value = value
			bestMove = move

	print_debug("minimax best value: " + str(best_value))
	print_debug("minimax best move: " + str(bestMove))
	return bestMove


func _make_move(board_state, move, player_turn):
	var moved_piece_type = board_state[move[STARTING_TILE_X]][move[STARTING_TILE_Y]]
	var promotion_piece_type = move[PROMOTION_PIECE]
	board_state[move[DESTINATION_TILE_X]][move[DESTINATION_TILE_Y]] = promotion_piece_type if promotion_piece_type != "" else moved_piece_type
	board_state[move[STARTING_TILE_X]][move[STARTING_TILE_Y]] = ""
	previous_moves.push_back(move)
	previous_num_pieces_maps.push_back(get_num_pieces(board_state, player_turn))
	
func _unmake_move(board_state):
	var move = previous_moves.pop_back()
	board_state[move[DESTINATION_TILE_X]][move[DESTINATION_TILE_Y]] = move[DESTINATION_PIECE]
	board_state[move[STARTING_TILE_X]][move[STARTING_TILE_Y]] = move[STARTING_PIECE]
	previous_num_pieces_maps.pop_back()
	
func _minimax(board_state, num_pieces_map, last_move, depth, alpha, beta, is_maximizing_player, cumulative_value):
	if depth == 0:
		return _evaluate_board(board_state, cumulative_value)

	if is_maximizing_player:
		var best_value = -INF
		var legal_moves = get_legal_moves(board_state, 2, last_move, num_pieces_map)
		#SortMoves(board, pseudoLegalMoves)
		for move in legal_moves:
			_make_move(board_state, move, 2) 
			var value = _minimax(board_state, previous_num_pieces_maps.back(), move,
				depth - 1, alpha, beta, false, 
				cumulative_value + piece_strength_map[move[DESTINATION_PIECE]])
			_unmake_move(board_state)

			best_value = max(value, best_value)
			alpha = max(alpha, value)

			if beta <= alpha:
				break
		
		return best_value
	
	else:
		var best_value = INF
		var legal_moves = get_legal_moves(board_state, 1, last_move, num_pieces_map)
		#SortMoves(board, pseudoLegalMoves)
		for move in legal_moves:
			_make_move(board_state, move, 1)
			var value = _minimax(board_state, previous_num_pieces_maps.back(), move, 
				depth - 1, alpha, beta, true,
				cumulative_value - piece_strength_map[move[DESTINATION_PIECE]])
			_unmake_move(board_state)

			best_value = min(value, best_value)
			beta = min(beta, value)

			if beta <= alpha:
				break

		return best_value
	
# Contrary to chess the value of a position depends on the captured pieces that happened upon reaching the current position.
# So, the current board position cannot be evaluated "in a vacuum", but it will keep track of all the captures
func _evaluate_board(_board_state, cumulative_value):
	#print_debug("Finished Minimax branch. Final value: " + str(cumulative_value))
	# TODO: consider promotion value in score
	return cumulative_value
	
# Thread must be disposed (or "joined"), for portability.
func _exit_tree():
	# Set exit condition to true.
	mutex.lock()
	exit_thread = true # Protect with Mutex.
	mutex.unlock()

	# Unblock by posting.
	semaphore.post()

	# Wait until it exits.
	thread.wait_to_finish()


		
func get_legal_moves(board_state, player_turn, last_move, num_pieces_map=null):
	var legal_moves = []
	var available_pieces = []
	var starting_row = 4 if player_turn == 1 else 0
	var ending_row = 8 if player_turn == 1 else 4
	for i in range(starting_row, ending_row):
		for j in range(0, 4):
			if board_state[i][j] != "":
				available_pieces.append([
					i,
					j,
					board_state[i][j]
				])
	for p in available_pieces:
		legal_moves.append_array(get_legal_moves_for_piece_coord(board_state, player_turn, p, last_move, num_pieces_map))
		
	return legal_moves

func get_legal_moves_for_piece_coord(board_state, player_turn, piece_coord, 
		last_move, num_pieces_map=null):
	var piece_coord_sx = piece_coord[PIECE_COORD_STARTING_X]
	var piece_coord_sy = piece_coord[PIECE_COORD_STARTING_Y]
	var piece_coord_piece_type = piece_coord[PIECE_COORD_PIECE_TYPE]
	
	var last_move_sx = last_move[STARTING_TILE_X]
	var last_move_sy = last_move[STARTING_TILE_Y]
	var last_move_dx = last_move[DESTINATION_TILE_X]
	var last_move_dy = last_move[DESTINATION_TILE_Y]
	
	var legal_moves = []
	var precomputed_moves
	match piece_coord_piece_type:
		"S": 
			precomputed_moves = MoveGeneration.preComputedSmallMoves[piece_coord_sx][piece_coord_sy]
		"M": 
			precomputed_moves = MoveGeneration.preComputedMediumMoves[piece_coord_sx][piece_coord_sy]
		"B": 
			precomputed_moves = MoveGeneration.preComputedBigMoves[piece_coord_sx][piece_coord_sy]
			
	for direction_index in range(0, 8):
		var moves = precomputed_moves[direction_index]
		for move in moves:
			var dx = move[0]
			var dy = move[1]
			var move_result = is_piece_movement_valid(board_state, player_turn, piece_coord_piece_type, 
				last_move_sx, last_move_sy,
				last_move_dx, last_move_dy,
				piece_coord_sx, piece_coord_sy, dx, dy, num_pieces_map, false)
			
			if not move_result[0]:
				break

			if is_reject_move(
				last_move_sx, last_move_sy, 
				last_move_dx, last_move_dy, 
				piece_coord_sx, piece_coord_sy, dx, dy):
				break
			
			legal_moves.append(
				_create_move(piece_coord_sx, piece_coord_sy,
					dx, dy, piece_coord_piece_type, board_state[dx][dy], move_result[1], 0)
			)
			
	return legal_moves


func _create_move(starting_tile_x, starting_tile_y, 
	destination_tile_x, destination_tile_y, 
	starting_piece, destination_piece, promotion_piece, score):
	return [
		starting_tile_x,
		starting_tile_y,
		destination_tile_x,
		destination_tile_y,
		starting_piece,
		destination_piece,
		promotion_piece,
		score
	]
	
func get_random_move(board):
	var legal_moves = get_legal_moves(board.board_state, 2,
		[board.previous_starting_tile_x, board.previous_starting_tile_y, 
			board.previous_destination_tile_x, board.previous_destination_tile_y])
	return legal_moves[randi() % len(legal_moves)]

func get_high_score_move(board):
	var board_state = board.board_state
	var legal_moves = get_legal_moves(board_state, 2, [board.previous_starting_tile_x, board.previous_starting_tile_y, 
			board.previous_destination_tile_x, board.previous_destination_tile_y])
	
	var max_score = 0
	for legal_move in legal_moves:
		legal_move[SCORE] = piece_strength_map[board_state[legal_move[DESTINATION_TILE_X]][legal_move[DESTINATION_TILE_Y]]]
		if legal_move[SCORE] > max_score:
			max_score = legal_move[SCORE]
		#print_debug(str(legal_move["starting_tile_x"]) + "," + str(legal_move["starting_tile_y"]) +
		#" --> " + str(legal_move["destination_tile_x"]) + "," + str(legal_move["destination_tile_y"]) + "[ Score: " + str(legal_move["score"]) + "]")	
	
	var high_scores = _get_moves_with_highest_score(legal_moves, max_score)
	return high_scores[randi() % len(high_scores)]
	
func _get_moves_with_highest_score(legal_moves, max_score):
	var high_score_moves = []
	for legal_move in legal_moves:
		if legal_move[SCORE] == max_score:
			high_score_moves.append(legal_move)
	return high_score_moves


func get_num_pieces(_board_state, player_turn):
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
			num_pieces_map[_board_state[i][j]] += 1 
	return num_pieces_map

func is_reject_move(_previous_starting_tile_x, _previous_starting_tile_y,
	_previous_destination_tile_x, _previous_destination_tile_y, 
	_starting_tile_x, _starting_tile_y,
	_destination_tile_x, _destination_tile_y):
	return _previous_starting_tile_x == _destination_tile_x and _previous_starting_tile_y == _destination_tile_y \
		and _previous_destination_tile_x == _starting_tile_x and _previous_destination_tile_y == _starting_tile_y

func is_piece_movement_valid(_board_state, player_turn, current_piece_type, 
	previous_starting_tile_x, previous_starting_tile_y,
	previous_destination_tile_x, previous_destination_tile_y,
	starting_tile_x, starting_tile_y, destination_tile_x, destination_tile_y,
	num_pieces_map=null, consider_reject_move=true):
	# cannot move piece to same position
	if starting_tile_x == destination_tile_x and starting_tile_y == destination_tile_y:
		return [false, ""]
	
	# cannot capture own piece
	var promotion_piece = _get_promotion_piece(_board_state, player_turn, 
		starting_tile_x, starting_tile_y, 
		destination_tile_x, destination_tile_y, num_pieces_map)
	if promotion_piece == "" \
		and (
			(destination_tile_x > 3 and player_turn == 1 and _board_state[destination_tile_x][destination_tile_y] != "") \
			or (destination_tile_x <= 3 and player_turn == 2 and _board_state[destination_tile_x][destination_tile_y] != "")
		):
		return [false, ""]
	
	# cannot "reject" move
	if consider_reject_move:
		if is_reject_move(previous_starting_tile_x, previous_starting_tile_y,
				previous_destination_tile_x, previous_destination_tile_y, 
				starting_tile_x, starting_tile_y,
				destination_tile_x, destination_tile_y):
			return [false, ""]
	
	match current_piece_type:
		"S":
			return [(destination_tile_x == starting_tile_x + 1 and destination_tile_y == starting_tile_y + 1) \
				or (destination_tile_x == starting_tile_x - 1 and destination_tile_y == starting_tile_y - 1) \
				or (destination_tile_x == starting_tile_x + 1 and destination_tile_y == starting_tile_y - 1) \
				or (destination_tile_x == starting_tile_x - 1 and destination_tile_y == starting_tile_y + 1), promotion_piece]
		"M":
			return [((destination_tile_x == starting_tile_x + 1 or (destination_tile_x == starting_tile_x + 2 and _board_state[starting_tile_x + 1][starting_tile_y] == "")) and destination_tile_y == starting_tile_y) \
				or ((destination_tile_x == starting_tile_x - 1 or (destination_tile_x == starting_tile_x - 2 and _board_state[starting_tile_x - 1][starting_tile_y] == "")) and destination_tile_y == starting_tile_y) \
				or ((destination_tile_y == starting_tile_y + 1 or (destination_tile_y == starting_tile_y + 2 and _board_state[starting_tile_x][starting_tile_y + 1] == "")) and destination_tile_x == starting_tile_x) \
				or ((destination_tile_y == starting_tile_y - 1 or (destination_tile_y == starting_tile_y - 2 and _board_state[starting_tile_x][starting_tile_y - 1] == "")) and destination_tile_x == starting_tile_x), promotion_piece]
		"B":
			if abs(starting_tile_x - destination_tile_x) == abs(starting_tile_y - destination_tile_y):
				for num_gaps in range(1, abs(starting_tile_x - destination_tile_x)):
					var i = starting_tile_x + num_gaps * (1 if destination_tile_x > starting_tile_x else -1)
					var j = starting_tile_y + num_gaps * (1 if destination_tile_y > starting_tile_y else -1)
					if _board_state[i][j] != "":
						return [false, promotion_piece]
				return [true, promotion_piece]

			if starting_tile_x == destination_tile_x:
				for i in range(min(starting_tile_y, destination_tile_y) + 1, max(starting_tile_y, destination_tile_y)):
					if _board_state[starting_tile_x][i] != "":
						return [false, promotion_piece]
				return [true, promotion_piece]
			
			if starting_tile_y == destination_tile_y:
				for i in range(min(starting_tile_x, destination_tile_x) + 1, max(starting_tile_x, destination_tile_x)):
					if _board_state[i][starting_tile_y] != "":
						return [false, promotion_piece]
				return [true, promotion_piece]
			
			return [false, promotion_piece]

	return [false, promotion_piece]

# If you have no Queens, you can create one by moving a Drone into a Pawn’s space (or vice versa)
# and merging them. Similarly, if you control no Drones, you can make one by merging two of your Pawns.
func _get_promotion_piece(_board_state, player_turn, starting_tile_x, starting_tile_y, 
	destination_tile_x, destination_tile_y, num_pieces_map=null):
	
	# Cannot promote when crossing canal
	if (starting_tile_x >= 4 and destination_tile_x <= 3) or (starting_tile_x <= 3 and destination_tile_x >= 4):
		return ""
	
	if num_pieces_map == null:
		num_pieces_map = get_num_pieces(_board_state, player_turn)
		
	if num_pieces_map["B"] == 0 and \
		((_board_state[starting_tile_x][starting_tile_y] == "S" and _board_state[destination_tile_x][destination_tile_y] == "M")
		or (_board_state[starting_tile_x][starting_tile_y] == "M" and _board_state[destination_tile_x][destination_tile_y] == "S")):
		return "B"
	if num_pieces_map["M"] == 0 and \
		(_board_state[starting_tile_x][starting_tile_y] == "S" and _board_state[destination_tile_x][destination_tile_y] == "S"):
		return "M"
	return ""


