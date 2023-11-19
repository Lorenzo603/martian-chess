extends Camera3D

@export var pyr: Node3D = null

func _ready():
	#look_at(pyr.global_position)
	
	#await get_tree().create_timer(2).timeout
	
	#pyr.get_node("Cone").get_surface_override_material(0).albedo_color = Color.WEB_GREEN
	
