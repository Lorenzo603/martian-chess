extends Sprite2D

@export var piece: Sprite2D = null

func get_piece():
	return piece

func set_piece(_piece):
	self.piece = _piece
