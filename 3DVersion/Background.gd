@tool
extends Sprite3D

func _process(delta):
	if Engine.is_editor_hint():
		visible = false
	else:
		visible = true
