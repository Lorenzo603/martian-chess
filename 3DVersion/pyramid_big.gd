extends Node3D

var is_dragging = false
@export var starting_tile_ref: MeshInstance3D = null

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
				is_dragging = true
		elif event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			if not is_dragging: # avoids triggering release on pieces in the destination tile
				return
			is_dragging = false
			
			var destination_tile = _get_destination_tile()

			if destination_tile == null:
				self.global_position = starting_tile_ref.get_node("PieceClampPosition").global_position
				return
			
			destination_tile.piece = self
			starting_tile_ref = destination_tile
			self.global_position = destination_tile.get_node("PieceClampPosition").global_position
			
			
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
