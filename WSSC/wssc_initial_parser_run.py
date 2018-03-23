import leak_process
import epanet_call
from random import randint
import math
import numpy as np
from epanet_call import epanet_call
from leak_process import parse_input,parse_output,isConnected,leakMatrixCreation

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

print len(unique_node_list)

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
	# print(connected_time)
	# thefile = open("../Output/WSSC/isconnectedlist.txt","w")
	# for item in isConnected_list:
 # 		print>>thefile, item
 # 	thefile = open("../Output/WSSC/connecteddistance.txt","w")
	# for item in connected_distance:
 # 		print>>thefile, item
 # 	thefile = open("../Output/WSSC/connectedvelocity.txt","w")
	# for item in connected_velocity:
 # 		print>>thefile, item
 # 	thefile = open("../Output/WSSC/connected_time.txt","w")
	# for item in connected_time:
 # 		print>>thefile, item

	distance_array,demand_shortage_array,detection_time_array,detection_capability_array = leakMatrixCreation(unique_node_list[i],unique_node_id,isConnected_list,connected_distance,connected_velocity,connected_time,node_first_time_store,node_second_time_store)

	final_detection_time_matrix.append(detection_time_array)
	final_distance_matrix.append(distance_array)
	final_demand_shortage_matrix.append(demand_shortage_array)
	final_detection_capability_matrix.append(detection_capability_array)


final_detection_time_matrix = np.asarray(final_detection_time_matrix).T
final_distance_matrix = np.asarray(final_distance_matrix).T
final_demand_shortage_matrix = np.asarray(final_demand_shortage_matrix).T
final_detection_capability_matrix = np.asarray(final_detection_capability_matrix).T



# np.savetxt("../Output/WSSC/detectionTime.csv", final_detection_time_matrix, delimiter=",")
# np.savetxt("../Output/WSSC/distance.csv", final_distance_matrix, delimiter=",")
# np.savetxt("../Output/WSSC/demandShortage.csv", final_demand_shortage_matrix, delimiter=",")
# np.savetxt("../Output/WSSC/detectionCapability.csv", final_detection_capability_matrix, delimiter=",")


# print final_detection_time_matrix
# print final_detection_capability_matrix
# print final_demand_shortage_matrix
# print final_distance_matrix