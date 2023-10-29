extends Sprite2D

const default_z_index = 1

@onready var board = get_node("../Board")

var is_dragging = false
var starting_position = self.global_position 
@export var starting_tile_x = 0
@export var starting_tile_y = 0
@export var starting_tile_ref: Sprite2D = null

func _process(delta):
	if is_dragging:
		#$".".global_position = lerp($".".global_position, get_global_mouse_position(), 10 * delta)
		self.global_position = get_global_mouse_position()


func _on_area_2d_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if board.is_piece_draggable(starting_tile_x, starting_tile_y):
				is_dragging = true
				starting_position = self.global_position
				self.z_index = RenderingServer.CANVAS_ITEM_Z_MAX
		elif event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			if not is_dragging: # avoids triggering release on pieces in the destination tile
				return
				
			is_dragging = false
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
			
		
