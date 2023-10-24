extends Label

const player = 2

func _on_board_score_changed(player, new_score):
	if player == self.player:
		text = str(new_score)
