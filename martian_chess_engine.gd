extends Node

@onready var board = get_node("../Main/Board")

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
	
