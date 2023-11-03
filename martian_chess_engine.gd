extends Node

signal minimax_tree_completed

const piece_strength_map = {
	"": 0,
	
	# Player 1
	"S": 1,
	"M": 2,
	"B": 3,
	
}

@onready var board = get_node("../Main/Board")

var best_move = null
var previous_moves = []

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
		
func get_best_move():
	semaphore.post()
	await minimax_tree_completed
	if best_move == null:
		print_debug("No best move found, returning best high score")
		best_move = get_high_score_move()
	return best_move
	
func _calculate_best_move():
	var best_value = INF # it is INF because we are loking for the best AI move, otherwise it would be -INF
	var bestMove = null
	previous_moves.clear()
	var board_state = board.board_state.duplicate(true)
	var depth = 2

	var legal_moves = get_legal_moves(board_state, 2)
	# SortMoves(board, pseudoLegalMoves);

	for move in legal_moves:
		_make_move(board_state, move)
		var cumulative_value = -piece_strength_map[move["destination_piece"]]
		var value = _minimax(board_state, depth, -INF, INF, true, cumulative_value)
		_unmake_move(board_state);
		
		# TODO save all best moves and pick a random one
		if value <= best_value: # it is <= because we are loking for the best AI move, otherwise it would be >=
			best_value = value
			bestMove = move

	print_debug("minimax best value: " + str(best_value))
	print_debug("minimax best move: " + str(bestMove))
	return bestMove


func _make_move(board_state, move):
	var moved_piece_type = board_state[move["starting_tile_x"]][move["starting_tile_y"]]
	var promotion_piece_type = move["promotion_piece"]
	board_state[move["destination_tile_x"]][move["destination_tile_y"]] = promotion_piece_type if promotion_piece_type != "" else moved_piece_type
	board_state[move["starting_tile_x"]][move["starting_tile_y"]] = ""
	previous_moves.push_back(move)
	
func _unmake_move(board_state):
	var move = previous_moves.pop_back()
	board_state[move["destination_tile_x"]][move["destination_tile_y"]] = move["destination_piece"]
	board_state[move["starting_tile_x"]][move["starting_tile_y"]] = move["starting_piece"]
	
func _minimax(board_state, depth, alpha, beta, is_maximizing_player, cumulative_value):
	if depth == 0:
		return _evaluate_board(board_state, cumulative_value)

	if is_maximizing_player:
		var best_value = -INF
		var legal_moves = get_legal_moves(board_state, 2)
		#SortMoves(board, pseudoLegalMoves)
		for move in legal_moves:
			_make_move(board_state, move) 
			var value = _minimax(board_state, depth - 1, alpha, beta, false, 
				cumulative_value + piece_strength_map[move["destination_piece"]])
			_unmake_move(board_state)

			best_value = max(value, best_value)
			alpha = max(alpha, value)

			if beta <= alpha:
				break
		
		return best_value
	
	else:
		var best_value = INF
		var legal_moves = get_legal_moves(board_state, 1)
		#SortMoves(board, pseudoLegalMoves)
		for move in legal_moves:
			_make_move(board_state, move)
			var value = _minimax(board_state, depth - 1, alpha, beta, true,
				cumulative_value - piece_strength_map[move["destination_piece"]])
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

	
func get_high_score_move():
	var board_state = board.board_state
	var legal_moves = get_legal_moves(board_state, 2)
	
	var max_score = 0
	for legal_move in legal_moves:
		legal_move["score"] = piece_strength_map[board_state[legal_move["destination_tile_x"]][legal_move["destination_tile_y"]]]
		if legal_move["score"] > max_score:
			max_score = legal_move["score"]
		#print_debug(str(legal_move["starting_tile_x"]) + "," + str(legal_move["starting_tile_y"]) +
		#" --> " + str(legal_move["destination_tile_x"]) + "," + str(legal_move["destination_tile_y"]) + "[ Score: " + str(legal_move["score"]) + "]")	
	
	var high_scores = _get_moves_with_highest_score(legal_moves, max_score)
	return high_scores[randi() % len(high_scores)]
	
func _get_moves_with_highest_score(legal_moves, max_score):
	var high_score_moves = []
	for legal_move in legal_moves:
		if legal_move["score"] == max_score:
			high_score_moves.append(legal_move)
	return high_score_moves
		
func get_legal_moves(board_state, player_turn):
	var legal_moves = []
	var available_pieces = []
	var starting_row = 4 if player_turn == 1 else 0
	var ending_row = 8 if player_turn == 1 else 4
	for i in range(starting_row, ending_row):
		for j in range(0, 4):
			if board_state[i][j] != "":
				available_pieces.append(
					{
						"sx": i,
						"sy": j,
						"piece_type": board_state[i][j]
				})
	for p in available_pieces:
		legal_moves.append_array(get_legal_moves_for_piece_coord(board_state, p))
		
	return legal_moves

func get_legal_moves_for_piece_coord(board_state, piece_coord):
	var legal_moves = []
	match piece_coord["piece_type"]:
		"S": 
			for i in [-1, 1]:
				for j in [-1, 1]:
					var dx = piece_coord["sx"] + i
					var dy = piece_coord["sy"] + j
					if 0 <= dx and dx <= 7 and 0 <= dy and dy <= 3:
						var move_result = board.is_piece_movement_valid(
							board_state, "S", 
							piece_coord["sx"], piece_coord["sy"], dx, dy)
						if move_result[0]:
							legal_moves.append({
								"starting_tile_x": piece_coord["sx"],
								"starting_tile_y": piece_coord["sy"],
								"destination_tile_x": dx,
								"destination_tile_y": dy,
								"starting_piece": "S",
								"destination_piece": board_state[dx][dy],
								"promotion_piece": move_result[1]
							})
		"M": 
			for i in [-2, -1, 1, 2]:
				var dx = piece_coord["sx"] + i
				var dy = piece_coord["sy"]
				if 0 <= dx and dx <= 7 and 0 <= dy and dy <= 3:
					var move_result = board.is_piece_movement_valid(
						board_state, "M", 
						piece_coord["sx"], piece_coord["sy"], dx, dy)
					if move_result[0]:
						legal_moves.append({
							"starting_tile_x": piece_coord["sx"],
							"starting_tile_y": piece_coord["sy"],
							"destination_tile_x": dx,
							"destination_tile_y": dy,
							"starting_piece": "M",
							"destination_piece": board_state[dx][dy],
							"promotion_piece": move_result[1]
						})
			for j in [-2, -1, 1, 2]:
				var dx = piece_coord["sx"]
				var dy = piece_coord["sy"] + j
				if 0 <= dx and dx <= 7 and 0 <= dy and dy <= 3:
					var move_result = board.is_piece_movement_valid(
						board_state, "M", 
						piece_coord["sx"], piece_coord["sy"], dx, dy)
					if move_result[0]:
						legal_moves.append({
							"starting_tile_x": piece_coord["sx"],
							"starting_tile_y": piece_coord["sy"],
							"destination_tile_x": dx,
							"destination_tile_y": dy,
							"starting_piece": "M",
							"destination_piece": board_state[dx][dy],
							"promotion_piece": move_result[1]
						})
						
		"B": 
			for i in range(0, 8):
				for j in range(0, 4):
					if not (i == piece_coord["sx"] and j == piece_coord["sy"]):
						var move_result = board.is_piece_movement_valid(
							board_state, "B", 
							piece_coord["sx"], piece_coord["sy"], i, j)
						if move_result[0]:
							legal_moves.append({
								"starting_tile_x": piece_coord["sx"],
								"starting_tile_y": piece_coord["sy"],
								"destination_tile_x": i,
								"destination_tile_y": j,
								"starting_piece": "B",
								"destination_piece": board_state[i][j],
								"promotion_piece": move_result[1]
							})
	return legal_moves
	
func get_random_move():
	var legal_moves = get_legal_moves(board.board_state, 2)
	return legal_moves[randi() % len(legal_moves)]
