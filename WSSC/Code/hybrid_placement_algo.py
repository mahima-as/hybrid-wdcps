import pandas as pd
import numpy as np
import os
from numpy import inf
from numpy import random
import csv


read_input = open("../../Data/UCI_WSSC_Pressure_Zone_EPANET.inp",'r')

def parse_input(read_input):
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

	detectionCapability = np.genfromtxt("../../Output/WSSC/detectionCapability.csv", delimiter=',')

	detection_weight_number = []      # Array to store the number of nodes detectable by each node to obtain weight later
	for i in xrange(0,len(detectionCapability)):
		current_line = detectionCapability[i]
		detection_number = [j for j,v in enumerate(current_line) if v==1]
		detection_number = len(detection_number)
		detection_weight_number.append(detection_number)

	detectionTime = np.genfromtxt("../../Output/WSSC/detectionTime.csv", delimiter=',')
	impactMatrix = pd.read_csv("final_impact_matrix.csv")
	impactMatrix = impactMatrix.values
	impactMatrix = [row[1:] for row in impactMatrix]
	triangle_score = np.genfromtxt("final_triangle_score.csv",delimiter=",",skip_header=1)
	
	# print(detectionCapability)
	# print(detectionTime)
	# print(impactMatrix)
	# print(triangle_score)
	return(unique_node_id,detectionCapability,detectionTime,triangle_score,impactMatrix,detection_weight_number)



# The below function takes as input the node for which the utility score is to be computed
# It identifies the impacted triangles and then computes the product of triangle score * impact(triangle)
# for each of the impacted triangles and returns the score
def computeTriangleImpactProduct(impact_matrix,triangle_score,node_index):
	score = 0
	impacted_indices = [j for j,v in enumerate(impact_matrix[node_index]) if v > 0]
	for index in impacted_indices:
		score = score + (impact_matrix[node_index][index] * triangle_score[index])
	return(score)