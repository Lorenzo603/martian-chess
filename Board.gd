extends Node

signal score_changed(player, captured_pieces, new_score)
signal game_ended

const MAX_PLAYERS = 2

@onready var game_mode: GlobalState.GameMode = GlobalState.game_mode
@export var player_turn: int = 1

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
	if player_turn == 2:
		SignalBus.end_turn.emit()
		
func update_player_turn():
	player_turn += 1
	if player_turn > MAX_PLAYERS:
		player_turn = 1

func is_piece_draggable(starting_tile_x):
	return not game_over and \
		(
			(starting_tile_x > 3 and player_turn == 1) 
			or (starting_tile_x <=3 and player_turn == 2 and game_mode == GlobalState.GameMode.TWO_PLAYER)
		)

func is_move_valid(starting_tile_x, starting_tile_y, destination_tile_x, destination_tile_y):
	print_debug(str(starting_tile_x) + "," + str(starting_tile_y) + "[" + board_state[starting_tile_x][starting_tile_y] + "]" +
		" --> " + str(destination_tile_x) + "," + str(destination_tile_y) + "[" + board_state[destination_tile_x][destination_tile_y] + "]")	
	
	var current_piece_type = board_state[starting_tile_x][starting_tile_y]
	var is_movement_valid_result = MartianChessEngine.is_piece_movement_valid(board_state, 
		player_turn, current_piece_type, 
		previous_starting_tile_x, previous_starting_tile_y,
		previous_destination_tile_x, previous_destination_tile_y,
		starting_tile_x, starting_tile_y, destination_tile_x, destination_tile_y)
	var is_movement_valid = is_movement_valid_result[0]
	var promotion_piece = is_movement_valid_result[1]
	
	var has_captured = false
	if is_movement_valid:
		# capture piece
		if board_state[destination_tile_x][destination_tile_y] != "":
			var captured_piece = board_state[destination_tile_x][destination_tile_y]
			captured_pieces[player_turn - 1].append(captured_piece)
			has_captured = true
			score_changed.emit(player_turn, captured_pieces, _calculate_score(captured_pieces[player_turn - 1]))
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
	


func _on_end_turn():
	if game_over:
		return
	
	var next_move = null
	match game_mode:
		GlobalState.GameMode.TWO_PLAYER:
			return
		GlobalState.GameMode.RANDOM_AI:
			await get_tree().create_timer(1.0).timeout
			next_move = MartianChessEngine.get_random_move(self)
		GlobalState.GameMode.HIGH_SCORE_AI:
			await get_tree().create_timer(1.0).timeout
			next_move = MartianChessEngine.get_high_score_move(self)
		GlobalState.GameMode.MINMAX_AI:
			await get_tree().create_timer(0.5).timeout
			next_move = await MartianChessEngine.get_best_move(self)
			#print_debug("moved on..." + str(next_move))
	
	var moved_piece = get_tile_by_coord(next_move[MartianChessEngine.STARTING_TILE_X], next_move[MartianChessEngine.STARTING_TILE_Y]).piece
	var destination_tile = get_tile_by_coord(next_move[MartianChessEngine.DESTINATION_TILE_X], next_move[MartianChessEngine.DESTINATION_TILE_Y])
	
	var move_result = is_move_valid(next_move[MartianChessEngine.STARTING_TILE_X], next_move[MartianChessEngine.STARTING_TILE_Y], 
		next_move[MartianChessEngine.DESTINATION_TILE_X], next_move[MartianChessEngine.DESTINATION_TILE_Y]
	)
	SignalBus.piece_moved.emit(moved_piece, move_result, 
		next_move[MartianChessEngine.DESTINATION_TILE_X], next_move[MartianChessEngine.DESTINATION_TILE_Y], 
		destination_tile)

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

func get_tile_by_coord(x, y):
	for t in get_tree().get_nodes_in_group("tiles"):
		if t.get_meta("TileCoordX") == x and t.get_meta("TileCoordY") == y:
			return t
	return null
