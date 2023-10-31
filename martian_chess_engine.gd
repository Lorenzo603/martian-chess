extends Node

signal minmax_tree_completed

const piece_strength_map = {
	"": 0,
	
	# Player 1
	"S": 1,
	"M": 2,
	"B": 3,
	
	# Player 2
	"S2": -1,
	"M2": -2,
	"B2": -3,
}

@onready var board = get_node("../Main/Board")

var best_move = null
var minmax_tree = null


func get_best_move():
	_calculate_minmax_tree.call()
	await minmax_tree_completed
	print_debug(minmax_tree)	
	best_move = {
		"starting_tile_x": 2,
		"starting_tile_y": 0,
		"destination_tile_x": 5,
		"destination_tile_y": 0
	}
	return best_move
	
func _calculate_minmax_tree():
	print_debug("Calculating Minmax tree...")
	await get_tree().create_timer(2.5).timeout
	minmax_tree = "MINMAX TREE COMPLETED"
	minmax_tree_completed.emit()
	
func get_high_score_move():
	var board_state = board.board_state
	var legal_moves = get_legal_moves()
	
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
		
func get_legal_moves():
	var legal_moves = []
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
		legal_moves.append_array(_get_legal_moves_for_piece_coord(p))
		
	return legal_moves

func _get_legal_moves_for_piece_coord(piece_coord):
	var board_state = board.board_state
	var legal_moves = []
	match piece_coord["piece_type"]:
		"S": 
			for i in [-1, 1]:
				for j in [-1, 1]:
					var dx = piece_coord["sx"] + i
					var dy = piece_coord["sy"] + j
					if 0 <= dx and dx <= 7 and 0 <= dy and dy <= 3 \
						and board.is_piece_movement_valid("S", piece_coord["sx"], piece_coord["sy"], 
								dx, dy)[0]:
						legal_moves.append({
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
					legal_moves.append({
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
					legal_moves.append({
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
						legal_moves.append({
							"starting_tile_x": piece_coord["sx"],
							"starting_tile_y": piece_coord["sy"],
							"destination_tile_x": i,
							"destination_tile_y": j
						})
	return legal_moves
	
func get_random_move():
	var legal_moves = get_legal_moves()
	return legal_moves[randi() % len(legal_moves)]
