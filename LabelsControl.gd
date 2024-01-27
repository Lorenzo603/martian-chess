extends Control

@onready var player_1_score = $VBoxContainer/HBoxContainer/Player1Score
@onready var player_2_score = $VBoxContainer2/HBoxContainer/Player2Score

@onready var p1_captured_big = $VBoxContainer/HBoxContainer2/P1CapturedBigLabel
@onready var p1_captured_medium = $VBoxContainer/HBoxContainer3/P1CapturedMediumLabel
@onready var p1_captured_small = $VBoxContainer/HBoxContainer4/P1CapturedSmallLabel
@onready var p2_captured_big = $VBoxContainer2/HBoxContainer2/P2CapturedBigLabel
@onready var p2_captured_medium = $VBoxContainer2/HBoxContainer3/P2CapturedMediumLabel
@onready var p2_captured_small = $VBoxContainer2/HBoxContainer4/P2CapturedSmallLabel


func _on_score_changed(player, captured_pieces, new_score):
	var captured_piece = captured_pieces[player - 1][-1]
	var captured_piece_count = _calculate_captured_piece_count(captured_pieces, captured_piece, player)
	if player == 1:
		player_1_score.text = str(new_score)
		match captured_piece:
			"S": p1_captured_small.text = "x %s" % captured_piece_count
			"M": p1_captured_medium.text = "x %s" % captured_piece_count
			"B": p1_captured_big.text = "x %s" % captured_piece_count
	elif player == 2:
		player_2_score.text = str(new_score)
		match captured_piece:
			"S": p2_captured_small.text = "x %s" % captured_piece_count
			"M": p2_captured_medium.text = "x %s" % captured_piece_count
			"B": p2_captured_big.text = "x %s" % captured_piece_count	
	
func _calculate_captured_piece_count(captured_pieces, captured_piece, player):
	var count = 0
	for piece in captured_pieces[player - 1]:
		if piece == captured_piece:
			count += 1
	return count
	
