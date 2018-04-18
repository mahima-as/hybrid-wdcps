from collections import defaultdict


def find(lst, key, value):
    for i, dic in enumerate(lst):
        if dic[key] == value:
            return i

def count_less_than(list, value):
	count = 0
	for element in list:
		if element <= value:
			count = count + 1
	return count

	
def find_min_index(matrix):
	min = matrix[0][0]
	i = 0
	j = 0
	min_i = 0
	min_j = 0
	for row in matrix:
		j = 0
		for element in row:
			if element < min:
				min = element
				min_i = i
				min_j = 0
			j = j+1
		i = i+1
	return min, min_i, min_j