extends Node3D

@onready var board = get_node("../BoardLogic")

var is_dragging = false
@export var starting_tile_x = 0
@export var starting_tile_y = 0
@export var starting_tile_ref: MeshInstance3D = null

var legal_moves_markers = []

func _process(_delta):
	if is_dragging:
		# Drag piece
		var viewport = get_viewport()
		var mouse_position = viewport.get_mouse_position()
		var camera = viewport.get_camera_3d()
		
		var origin := camera.project_ray_origin(mouse_position)
		var direction := camera.project_ray_normal(mouse_position)
		
		var draggin_object_distance = 5
		var end = origin + direction * draggin_object_distance
		self.global_position = end


func _on_user_select_piece_area_3d_input_event(camera, event, _position, _normal, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if board.is_piece_draggable(starting_tile_x):
				is_dragging = true
				# TODO: draw legal moves
		elif event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			if not is_dragging: # avoids triggering release on pieces in the destination tile
				return
			is_dragging = false
			# TODO:stop drawing legal moves
			
			var destination_tile = _get_destination_tile()
			if destination_tile == null:
				self.global_position = starting_tile_ref.get_node("PieceClampPosition").global_position
				return
			
			var destination_tile_x = destination_tile.get_meta("TileCoordX")
			var destination_tile_y = destination_tile.get_meta("TileCoordY")
			
			var move_result = board.is_move_valid(starting_tile_x, starting_tile_y, 
				destination_tile_x, destination_tile_y
			)
			var is_movement_valid = move_result[0]
			if not is_movement_valid:
				self.global_position = starting_tile_ref.get_node("PieceClampPosition").global_position
				return
			
			SignalBus.piece_moved.emit(self, move_result, destination_tile_x, destination_tile_y, 
				destination_tile)
				
			SignalBus.end_turn.emit()
			
func _get_destination_tile():
	var viewport = get_viewport()
	var mouse_position = viewport.get_mouse_position()
	var camera = viewport.get_camera_3d()
	
	var origin := camera.project_ray_origin(mouse_position)
	var direction := camera.project_ray_normal(mouse_position)
	
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 1000, 2)
	query.collide_with_areas = true
	var result := space_state.intersect_ray(query)
	
	if not result.is_empty():
		var tile = result["collider"].get_parent()
		return tile
	return null
