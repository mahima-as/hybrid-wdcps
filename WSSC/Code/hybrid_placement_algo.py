import pandas as pd
import numpy as np
import os
from numpy import inf
from numpy import random
import csv

def parse_input(input_file):
	read_input = open(input_file,'r')
	lines = [line.rstrip('\r\n') for line in read_input]
	read_input.close()
	lines = [element.replace(' ','') for element in lines]
	lines = [element.replace('\t',' ') for element in lines]
	junction_index = lines.index('[JUNCTIONS]')
	reservoir_index = lines.index('[RESERVOIRS]')
	NUMBER_OF_JUNCTIONS = reservoir_index - junction_index - 3
	junction_index += 2
	node_list = list()
	for i in xrange(0,NUMBER_OF_JUNCTIONS):
		current_line = lines[junction_index+i]
		current_line = list(current_line.split()[:4])
		node_list.append(current_line)
		
	node_input_df = pd.DataFrame(node_list,columns=['id','elevation','demand','pattern'])
	unique_node_id = list(node_input_df['id'])

	detectionCapability = np.genfromtxt("../Output/detectionCapability.csv", delimiter=',')

	traversalCapability = np.genfromtxt("../Output/traversalCapability.csv",delimiter=",")

	traversalTime = np.genfromtxt("../Output/traversalTime.csv",delimiter=",")

	detection_weight_number = []      # Array to store the number of nodes detectable by each node to obtain weight later
	for i in xrange(0,len(detectionCapability)):
		current_line = detectionCapability[i]
		detection_number = [j for j,v in enumerate(current_line) if v==1]
		detection_number = len(detection_number)
		detection_weight_number.append(detection_number)

	detectionTime = np.genfromtxt("../Output/detectionTime.csv", delimiter=',')
	impactMatrix = pd.read_csv("../Output/final_impact_matrix.csv")
	impactMatrix = impactMatrix.values
	impactMatrix = [row[1:] for row in impactMatrix]
	triangle_score = np.genfromtxt("../Output/final_triangle_score.csv",delimiter=",",skip_header=1)
	
	# print(detectionCapability)
    # print(detectionTime)
	# print(impactMatrix)
	# print(triangle_score)
	print traversalCapability
	print traversalTime
	return(unique_node_id,detectionCapability,detectionTime,triangle_score,impactMatrix,detection_weight_number, traversalCapability, traversalTime)


# The below function takes as input the node for which the utility score is to be computed
# It identifies the impacted triangles and then computes the product of triangle score * impact(triangle)
# for each of the impacted triangles and returns the score
def computeTriangleImpactProduct(impact_matrix,triangle_score,node_index):
	score = 0
	impacted_indices = [j for j,v in enumerate(impact_matrix[node_index]) if v > 0]
	for index in impacted_indices:
		score = score + (impact_matrix[node_index][index] * triangle_score[index])
	return(score)


def computeUtility(unique_node_id,current_sensor_id,detectionTime,traversalTime,impactMatrix,static_sensor_cost,mobile_sensor_cost):
	''' Function that computes the utility score of adding a sensor. 
	Utility of adding a static sensor = Sum(Impact_ j / DetectionTime_ j) / CostofStatic , where j is iterated over the detectable leaks
	Utility of adding a mobile sensor = Sum(Impact_ j / DetectionTime_ j + TraversalTime_ j) / CostofMobile * Number of sensors , where j is iterated over the detectable leaks
	'''

	return final_utility_score

def hybridAlgorithm(unique_node_id, detectionCapability, detectionTime, traversalCapability, traversalTime, impactMatrix, triangle_score):
	''' Hybrid algorithm function that returns the final sensor placement locations. For mobile sensor locations it also returns
	the number of sensors deployed '''


	isCovered_list = [False] * len(unique_node_id)
	isCovered_list[0] = True
	sensor_placed = []
	
	mobile_sensor_placed = [False] * len(unique_node_id)
	static_sensor_placed = [False] * len(unique_node_id)

	uncovered_indices = [index for index,v in enumerate(isCovered_list) if v == False]
	node_shortest_detection_time_list = [float("inf")] * len(unique_node_id)

	while len(uncovered_indices) > 0:
		print len(uncovered_indices)
		utility_score = []
		for i in xrange(0,len(unique_node_id)):
			if mobile_sensor_placed[i] == True and static_sensor_placed[i] == True:
				utility_score.append(-1)
				continue





if __name__ == "__main__":
	input_file = "../Data/final_input.inp"
	unique_node_id, detectionCapability, detectionTime, triangle_score, impactMatrix, detection_weight_number, traversalCapability, traversalTime = parse_input(input_file)
