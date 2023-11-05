extends Node


func _on_button_button_up():
	get_tree().change_scene_to_file("res://Main2D.tscn")


func _on_button_2_button_up():
	get_tree().change_scene_to_file("res://Main3D.tscn")
