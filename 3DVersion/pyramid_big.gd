extends Node3D


var is_dragging = false

func _process(_delta):
	if is_dragging:
		var viewport = get_viewport()
		var mouse_position = viewport.get_mouse_position()
		var camera = viewport.get_camera_3d()
		
		var origin := camera.project_ray_origin(mouse_position)
		var direction := camera.project_ray_normal(mouse_position)
		
		var ray_length = 5
		var end = origin + direction * ray_length
		
		#var space_state := get_world_3d().direct_space_state
		#var query := PhysicsRayQueryParameters3D.create(origin, end)
		#var result := space_state.intersect_ray(query)
		
		#var mouse_position_3D = end
		#if not result.is_empty():
		#	mouse_position_3D = result["position"]
		
		self.global_position = end


func _on_user_select_piece_area_3d_input_event(camera, event, _position, _normal, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				is_dragging = true
				
		elif event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			if not is_dragging: # avoids triggering release on pieces in the destination tile
				return
			
			is_dragging = false
				
			
