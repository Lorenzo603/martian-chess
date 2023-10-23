extends Sprite2D

@onready var board = get_node("../Board")

var canDrag = false
var starting_position = self.global_position 

func _process(delta):
	if canDrag:
		#$".".global_position = lerp($".".global_position, get_global_mouse_position(), 10 * delta)
		self.global_position = get_global_mouse_position()


func _on_area_2d_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			canDrag = true
			starting_position = self.global_position
		elif event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			canDrag = false
			var has_moved_on_tile = $DragOverlapArea2D.has_overlapping_areas()
			if not has_moved_on_tile:
				self.global_position = starting_position
				return
				
			var overlapping_tile_area = $DragOverlapArea2D.get_overlapping_areas()[0]
			var overlapping_tile = overlapping_tile_area.get_parent()
			print_debug(str(overlapping_tile.get_meta("TileCoordX")) + "," + str(overlapping_tile.get_meta("TileCoordY")))
			
			var is_move_valid = board.is_move_valid()
			if not is_move_valid:
				self.global_position = starting_position
				return
				
			# TODO update board state	
			var clamp_position = overlapping_tile.get_node("PieceClampPosition").global_position
			self.global_position = clamp_position
			
			

