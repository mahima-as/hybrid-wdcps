import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import math
import itertools
from itertools import combinations

init_array = np.loadtxt(open("../Output/detectionCapability1.csv", "rb"), delimiter=",")
range_arr = range(0,len(init_array))

placed_locations = [False] * len(init_array)
covered_locations = [False] * len(init_array)
covered_locations = np.array(covered_locations)

uncovered_indices = range(0,len(init_array))
uncovered_indices = np.array(uncovered_indices)

covered_indices = np.empty(shape=(0,0))
uncovered_pairwise_indices = np.empty(shape=(0,0))
temp_counter = 0

pairwise_event_queue = []

parent_indices_of_ones = []

final_sensor_location = []

while(np.sum(covered_locations) != len(init_array)):
	# print temp_counter
	# temp_counter += 1
	print sum(placed_locations)
# print init_array
# for i in xrange(0,10):
	score = np.zeros(len(init_array))
	uncovered_number = len(np.where(covered_locations == False)[0])
	if(uncovered_number==1):
		last_location = np.where(covered_locations==False)[0]
		placed_locations[last_location] = True
		break
	print uncovered_number
	for i in xrange(0,len(init_array)):
		if placed_locations[i] == True:
			continue
		current_row = init_array[i]
		number_of_ones = (current_row == 1).sum()
		indices_of_ones = np.where(current_row == True)[0]
		number_of_intersections = len(np.intersect1d(indices_of_ones,covered_indices))
		nval = number_of_ones - number_of_intersections
		x_score = nval * (uncovered_number - nval)
		if uncovered_number == nval:
			x_score = nval

		y_score = 0
		for item in pairwise_event_queue:
			if current_row[item[0]] != current_row[item[1]]:
				y_score+=1

		current_score = x_score + y_score
		score[i] = current_score
		# print("HELLO")
		# print uncovered_number
		# print number_of_ones
		# print number_of_intersections
		# print nval
		# print indices_of_ones
		# print x_score
		# print y_score
		# print current_score

	current_iteration_location = np.argmax(score)

	current_row = init_array[current_iteration_location]
	number_of_ones = (current_row == 1).sum()
	indices_of_ones = np.where(current_row == True)[0]
	
	placed_locations[current_iteration_location] = True
	final_sensor_location.append(current_iteration_location)
	covered_locations[indices_of_ones] = True
	covered_indices = np.append(covered_indices,indices_of_ones)
	covered_indices = np.unique(covered_indices)

	uncovered_indices = np.array(list(set(uncovered_indices) - set(covered_indices)))


	pairwise_queue_detected_by_current = []
	for item in pairwise_event_queue:
		if current_row[item[0]] != current_row[item[1]]:
			pairwise_queue_detected_by_current.append(item)

	pairwise_event_queue = [combination for combination in pairwise_event_queue if combination not in pairwise_queue_detected_by_current]

	indices_of_ones = indices_of_ones.tolist()
	removal_array = []
	for i in xrange(0,len(indices_of_ones)):
		if indices_of_ones[i] in parent_indices_of_ones:
			removal_array.append(indices_of_ones[i])
	indices_of_ones = [element for element in indices_of_ones if element not in removal_array]

	parent_indices_of_ones.extend(indices_of_ones)

	pairwise_events_not_detected_by_current = combinations(indices_of_ones,2)
	for subset in pairwise_events_not_detected_by_current:
		pairwise_event_queue.append(list(subset))

	pairwise_event_queue_set = set(map(tuple,pairwise_event_queue))     #Removing all duplicates from the list. Shouldn't have duplicates in the first place
	pairwise_event_queue = map(list,pairwise_event_queue_set)


	# print("starting")
	# print score
	# print placed_locations
	# print current_row
	# print covered_locations
	# print covered_indices
	# print uncovered_indices
	# print pairwise_event_queue
print placed_locations
print sum(placed_locations)


np.savetxt("./sensorLocations/pure_static_coverage_driven.csv",placed_locations,delimiter=",")
# print init_array

