@tool
extends Sprite3D

func _process(_delta):
	if Engine.is_editor_hint():
		visible = false
	else:
		visible = true
