extends Node

func _on_button_pressed():
	get_tree().change_scene_to_file("res://Main2D.tscn")


func _on_button_2_pressed():
	get_tree().change_scene_to_file("res://3DVersion/Main3D.tscn")


func _on_item_list_item_selected(index):
	match index:
		0: GlobalState.game_mode = GlobalState.GameMode.TWO_PLAYER
		1: GlobalState.game_mode = GlobalState.GameMode.RANDOM_AI
		2: GlobalState.game_mode = GlobalState.GameMode.HIGH_SCORE_AI
		3: GlobalState.game_mode = GlobalState.GameMode.MINMAX_AI

