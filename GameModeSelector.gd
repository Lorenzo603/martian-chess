extends ItemList


func _ready():
	var selected_index = 3
	select(selected_index)
	item_selected.emit(selected_index)
