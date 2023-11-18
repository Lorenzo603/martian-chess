extends MeshInstance3D

@export var piece: Node3D = null
@export var tile_color: Color = Color.FLORAL_WHITE

func get_piece():
	return piece

func set_piece(_piece):
	self.piece = _piece

func _ready():
	get_surface_override_material(0).albedo_color = tile_color
