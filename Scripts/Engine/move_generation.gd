extends Node

# premove arrays are 4-dimensional arrays
# dimension 1: row index of the starting tile - range(0, 7)
# dimension 2: column index of the starting tile - range(0, 4)
# dimension 3: array of size 8 with each element representing a direction:
#		[u, ur, r, dr, d, dl, l, ul]
# dimension 4: array of size 2 with each element representing the destination tile x and y respectively

var preComputedSmallMoves = []
var preComputedMediumMoves = []
var preComputedBigMoves = []

func _ready():
	preComputedSmallMoves.resize(8)
	preComputedMediumMoves.resize(8)
	preComputedBigMoves.resize(8)
	
	for i in range(0, 8):
		var columns_arr = []
		columns_arr.resize(4)
		for j in range(0, 4):
			var directions_arr = []
			directions_arr.resize(8)
			for k in range(0, 8):
				directions_arr[k] = []
			columns_arr[j] = directions_arr
		
		preComputedSmallMoves[i] = columns_arr
		preComputedMediumMoves[i] = columns_arr.duplicate(true)
		preComputedBigMoves[i] = columns_arr.duplicate(true)
	
	_precompute_small_moves()
	_precompute_medium_moves()
	_precompute_big_moves()
		
		
func _precompute_small_moves():
	for x in range(0, 8):
		for y in range(0, 4):
			for i in [-1, 1]:
				for j in [-1, 1]:
					var dx = x + i
					var dy = y + j
					if 0 <= dx and dx <= 7 and 0 <= dy and dy <= 3:
						preComputedSmallMoves[x][y][_get_direction_index_small(i, j)].append([dx, dy])

func _get_direction_index_small(i, j):
	if i == -1:
		return 7 if j == -1 else 1
	else:
		return 5 if j == -1 else 3
	
func _precompute_medium_moves():
	for x in range(0, 8):
		for y in range(0, 4):
			for i in [-1, -2, 1, 2]:
				var dx = x + i
				if 0 <= dx and dx <= 7:
					preComputedMediumMoves[x][y][_get_direction_index_medium(i, false)].append([dx, y])
			for j in [-1, -2, 1, 2]:
				var dy = y + j
				if 0 <= dy and dy <= 3:
					preComputedMediumMoves[x][y][_get_direction_index_medium(j, true)].append([x, dy])

func _get_direction_index_medium(i, horizontal):
	if horizontal:
		return 6 if i < 0 else 2
	else:
		return 0 if i < 0 else 4
							
func _precompute_big_moves():
	for x in range(0, 8):
		for y in range(0, 4):
			
			for i in range(x-1, -1, -1):
				preComputedBigMoves[x][y][0].append([i, y])
			for i in range(x+1, 8):
				preComputedBigMoves[x][y][4].append([i, y])
				
			for j in range(y-1, -1, -1):
				preComputedBigMoves[x][y][6].append([x, j])
			for j in range(y+1, 4):
				preComputedBigMoves[x][y][2].append([x, j])
			
			_compute_diagonals(x, y, [-1, -2, -3], 7)
			_compute_diagonals(x, y, [1, 2, 3], 3)
			_compute_diagonals_opposite(x, y, [-1, -2, -3], 1)
			_compute_diagonals_opposite(x, y, [1, 2, 3], 5)
			
					
func _compute_diagonals(x, y, steps, direction_index):
	for step in steps:
		var dx = x + step
		var dy = y + step
		if 0 <= dx and dx <= 7 and 0 <= dy and dy <= 3:
			preComputedBigMoves[x][y][direction_index].append([dx, dy])
		

func _compute_diagonals_opposite(x, y, steps, direction_index):
	for step in steps:
		var dx = x + step
		var dy = y - step
		if 0 <= dx and dx <= 7 and 0 <= dy and dy <= 3:
			preComputedBigMoves[x][y][direction_index].append([dx, dy])
