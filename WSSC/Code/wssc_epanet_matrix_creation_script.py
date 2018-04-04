import wssc_leak_parse_script
import epanet_call
from random import randint
import math
import numpy as np
from epanet_call import epanet_call
from wssc_leak_parse_script import parse_input,parse_output,isConnected,leakMatrixCreation,mobileMatrixCreation

file_path = "../Data/final_input.inp"
output_file_path = "../Data/final_output.txt"

file = open(file_path)

lines = [line.rstrip('\n') for line in file]

file.close()


# lines = [element.replace(' ','') for element in lines]
lines = [element.replace('\t',' ') for element in lines]		#Modifying inp file to match formatting remove newlines and tabs 
lines = [element.strip() for element in lines]
lines = [' '.join(element.split()) for element in lines]

junction_index = lines.index('[JUNCTIONS]')
reservoir_index = lines.index('[RESERVOIRS]')

NUMBER_OF_JUNCTIONS = reservoir_index - junction_index - 3

junction_index += 2
unique_node_list = list()
for i in xrange(0,NUMBER_OF_JUNCTIONS):
	current_line = lines[junction_index+i]
	current_line = current_line.split()[0]
	unique_node_list.insert(len(unique_node_list),current_line)

emitter_index = lines.index('[EMITTERS]')
times_index = lines.index('[TIMES]')

final_detection_time_matrix = list()
final_distance_matrix = list()
final_demand_shortage_matrix = list()
final_detection_capability_matrix = list()
final_mobile_deployment_matrix = list()
final_mobile_deployment_time_matrix = list()

# print len(unique_node_list)

for i in xrange(0,len(unique_node_list)):
# for p in xrange(0,1):
# 	i=2
	print i
	emitter_line = ''
	emitter_line += str(unique_node_list[i]) + ' ' + str(300) + ' ' + str(1)
	file = open(file_path)
	replace_line = file.read().splitlines()
	file.close()

	replace_line[emitter_index + 2] = emitter_line
	file = open(file_path,"w").write('\n'.join(replace_line))	# writing emitter random leak start line to the input file
	
	epanet_call()

	NUMBER_OF_ELEMENTS,node_input_df,pipe_input_df = parse_input("../Data/final_input.inp")

	node_first_time_store,node_second_time_store,link_first_time_store,link_second_time_store = parse_output("../Data/final_output.txt", NUMBER_OF_ELEMENTS,unique_node_list[i])

	unique_node_id,isConnected_list,connected_distance,connected_velocity,connected_time = isConnected(node_input_df,pipe_input_df,node_first_time_store,node_second_time_store,link_first_time_store,link_second_time_store)

	distance_array,demand_shortage_array,detection_time_array,detection_capability_array,mobile_traversal_time_array = leakMatrixCreation(unique_node_list[i],unique_node_id,isConnected_list,connected_distance,connected_velocity,connected_time,node_first_time_store,node_second_time_store)

	mobile_traversal_array = mobileMatrixCreation(unique_node_list[i],unique_node_list,isConnected_list,connected_time)

	final_detection_time_matrix.append(detection_time_array)
	final_distance_matrix.append(distance_array)
	final_demand_shortage_matrix.append(demand_shortage_array)
	final_detection_capability_matrix.append(detection_capability_array)
	final_mobile_deployment_matrix.append(mobile_traversal_array)
	final_mobile_deployment_time_matrix.append(mobile_traversal_time_array)

final_detection_time_matrix = np.asarray(final_detection_time_matrix).T
final_distance_matrix = np.asarray(final_distance_matrix).T
final_demand_shortage_matrix = np.asarray(final_demand_shortage_matrix).T
final_detection_capability_matrix = np.asarray(final_detection_capability_matrix).T
final_mobile_deployment_matrix = np.asarray(final_mobile_deployment_matrix).T
final_mobile_deployment_time_matrix = np.asarray(final_mobile_deployment_time_matrix).T


np.savetxt("../Output/detectionTime.csv", final_detection_time_matrix, delimiter=",")
np.savetxt("../Output/distance.csv", final_distance_matrix, delimiter=",")
np.savetxt("../Output/demandShortage.csv", final_demand_shortage_matrix, delimiter=",")
np.savetxt("../Output/detectionCapability.csv", final_detection_capability_matrix, delimiter=",")
np.savetxt("../Output/mobileDeployment.csv",final_mobile_deployment_matrix,delimiter=",")
np.savetxt("../Output/traversalTime.csv",final_mobile_deployment_time_matrix,delimiter=",")


# Now given the mobile deployment matrix M, we compute higher orders of M (i.e.) M^2, M^3,... until entries converge to 0
# In each iteration we compute the traversal probability matrix T as a sum of the matrices. 

M = final_mobile_deployment_matrix
M_time = final_mobile_deployment_time_matrix

final_traversal_probability_matrix = final_mobile_deployment_matrix
final_traversal_time_matrix = final_mobile_deployment_time_matrix

while len(M[np.nonzero(M)]) > 0:			 # There exist non-zero elements
	current_length = len(M[np.nonzero(M)])
	M = np.dot(M,final_mobile_deployment_matrix)	
	# M_time = np.dot(M_time,final_mobile_deployment_time_matrix)
	if len(M[np.nonzero(M)]) == current_length:
		break
	final_traversal_probability_matrix = final_traversal_probability_matrix + M


np.savetxt("../Output/traversalProbability.csv",final_traversal_probability_matrix,delimiter=",")


# Now given traversal probability matrix, we compute the minimum number of sensors required to achieve the required coverage probability

REQUIRED_COVERAGE_PROBABILITY = 0.7
traversal_capability_matrix = final_traversal_probability_matrix
for i in xrange(0,len(unique_node_list)):
	for j in xrange(0,len(unique_node_list)):
		if final_traversal_probability_matrix[i][j] == 0:
			traversal_capability_matrix[i][j] = 0
		elif final_traversal_probability_matrix[i][j] == 1:
			traversal_capability_matrix[i][j] = 1
		else:
			number_of_sensors = np.log(1 - REQUIRED_COVERAGE_PROBABILITY) / np.log(1 - final_traversal_probability_matrix[i][j])
			traversal_capability_matrix[i][j] = max(final_traversal_probability_matrix[i][j],math.ceil(number_of_sensors))

np.savetxt("../Output/traversalCapability.csv",traversal_capability_matrix,delimiter=",")


print(isConnected_list)