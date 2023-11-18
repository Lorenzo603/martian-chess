extends Camera3D

@onready var pyr = $pyramid

func _ready():
	look_at(pyr.global_position)
	
	await get_tree().create_timer(2).timeout
	
	pyr.get_node("Cone").get_surface_override_material(0).albedo_color = Color.WEB_GREEN
	
