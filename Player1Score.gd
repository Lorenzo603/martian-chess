extends Label

const player = 1

func _on_board_score_changed(player, new_score):
	if player == self.player:
		text = str(new_score)
