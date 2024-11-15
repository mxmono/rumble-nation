extends Node


func get_array_overlap(arr1: Array, arr2: Array) -> Array:
	"""Get overlap elements of two arrays."""
	
	var arr = []
	for item in arr1:
		if arr2.has(item):
			if not arr.has(item):
				arr.append(item)
	
	return arr


func union_set(arr1: Array, arr2: Array) -> Array:
	"""Get unique items from both arrays."""
	
	var arr = []
	for item in arr1 + arr2:
		if not arr.has(item):
			arr.append(item)
	
	return arr
