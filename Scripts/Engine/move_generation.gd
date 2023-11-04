extends Node

var preComputedSmallMoves = []
var preComputedMediumMoves = []
var preComputedBigMoves = []

func _ready():
	preComputedSmallMoves.resize(8)
	preComputedMediumMoves.resize(8)
	preComputedBigMoves.resize(8)
	
	for i in range(0, 8):
		var arr = []
		arr.resize(4)
		for j in range(0, 4):
			arr[j] = []
		preComputedSmallMoves[i] = arr
		preComputedMediumMoves[i] = arr.duplicate()
		preComputedBigMoves[i] = arr.duplicate()
	
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
						preComputedSmallMoves[x][y].append([dx, dy])

func _precompute_medium_moves():
	for x in range(0, 8):
		for y in range(0, 4):
			for i in [-2, -1, 1, 2]:
				var dx = x + i
				if 0 <= dx and dx <= 7:
					preComputedMediumMoves[x][y].append([dx, y])
			for j in [-2, -1, 1, 2]:
				var dy = y + j
				if 0 <= dy and dy <= 3:
					preComputedMediumMoves[x][y].append([x, dy])
					
							
func _precompute_big_moves():
	for x in range(0, 8):
		for y in range(0, 4):
			for i in range(0, 8):
				if i != x:
					preComputedBigMoves[x][y].append([i, y])
			for j in range(0, 4):
				if j != y:
					preComputedBigMoves[x][y].append([x, j])

			for step in [-3, -2, -1, 1, 2, 3]:
				var dx = x + step
				var dy = y + step
				if 0 <= dx and dx <= 7 and 0 <= dy and dy <= 3:
					preComputedBigMoves[x][y].append([dx, dy])
				
				dy = y - step
				if 0 <= dx and dx <= 7 and 0 <= dy and dy <= 3:
					preComputedBigMoves[x][y].append([dx, dy])
				
				
					
