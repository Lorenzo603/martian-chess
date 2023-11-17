extends Camera3D

@onready var pyr = $pyramid

func _ready():
	look_at(pyr.global_position)
	
	await get_tree().create_timer(2).timeout
	
	pyr.get_node("Cone").material_override.albedo_color = Color.WEB_GREEN
	
