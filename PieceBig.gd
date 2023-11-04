extends Sprite2D

const default_z_index = 1

@onready var board = get_node("../Board")

var is_dragging = false
var starting_position = self.global_position 
@export var starting_tile_x = 0
@export var starting_tile_y = 0
@export var starting_tile_ref: Sprite2D = null

var legal_moves_markers = []

func _process(_delta):
	if is_dragging:
		#$".".global_position = lerp($".".global_position, get_global_mouse_position(), 10 * delta)
		self.global_position = get_global_mouse_position()


func _on_area_2d_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if board.is_piece_draggable(starting_tile_x):
				is_dragging = true
				starting_position = self.global_position
				self.z_index = RenderingServer.CANVAS_ITEM_Z_MAX
				_draw_legal_moves([
					starting_tile_x,
					starting_tile_y,
					board.board_state[starting_tile_x][starting_tile_y]	
				])
				
		elif event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			if not is_dragging: # avoids triggering release on pieces in the destination tile
				return
				
			is_dragging = false
			_stop_drawing_legal_moves()
			self.z_index = default_z_index
			var has_moved_on_tile = $DragOverlapArea2D.has_overlapping_areas()
			if not has_moved_on_tile:
				self.global_position = starting_position
				return
				
			var overlapping_tile_area = $DragOverlapArea2D.get_overlapping_areas()[0]
			var overlapping_tile = overlapping_tile_area.get_parent()
			
			var destination_tile_x = overlapping_tile.get_meta("TileCoordX")
			var destination_tile_y = overlapping_tile.get_meta("TileCoordY")
			
			
			var move_result = board.is_move_valid(starting_tile_x, starting_tile_y, 
				destination_tile_x, destination_tile_y
			)
			var is_movement_valid = move_result[0]
			if not is_movement_valid:
				self.global_position = starting_position
				return
			
			SignalBus.piece_moved.emit(self, move_result, destination_tile_x, destination_tile_y, 
				overlapping_tile)
				
			SignalBus.end_turn.emit()
			
			
func _draw_legal_moves(piece_coord):
	var legal_moves = MartianChessEngine.get_legal_moves_for_piece_coord(board.board_state, piece_coord)
	for move in legal_moves:
		# TODO: optimize by creating a method that gets the whole list of tiles in one go
		var tile = board.get_tile_by_coord(
			move[MartianChessEngine.DESTINATION_TILE_X], 
			move[MartianChessEngine.DESTINATION_TILE_Y]
		)
		var legal_move_marker = tile.get_node("LegalMoveMarker")
		legal_move_marker.visible = true
		legal_moves_markers.append(legal_move_marker)
	
func _stop_drawing_legal_moves():
	for marker in legal_moves_markers:
		marker.visible = false
	legal_moves_markers.clear()
