extends Label

const player = 1

func _on_board_score_changed(_player, new_score):
	if _player == self.player:
		text = str(new_score)
