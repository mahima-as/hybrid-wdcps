import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import math

def parse_input(file_path):
	file = open(file_path)

	lines = [line.rstrip('\n') for line in file]

	file.close()

	# lines = [element.replace(' ','') for element in lines]
	lines = [element.replace('\t',' ') for element in lines]		#Modifying inp file to match formatting remove newlines and tabs 
	lines = [element.strip() for element in lines]
	lines = [' '.join(element.split()) for element in lines]

	junction_index = lines.index('[JUNCTIONS]')
	reservoir_index = lines.index('[RESERVOIRS]')
	tanks_index = lines.index('[TANKS]')
	pipes_index = lines.index('[PIPES]')
	pumps_index = lines.index('[PUMPS]')
	valves_index = lines.index('[VALVES]')
	tags_index = lines.index('[TAGS]')

	NUMBER_OF_JUNCTIONS = reservoir_index - junction_index - 3
	NUMBER_OF_RESERVOIRS = tanks_index - reservoir_index - 3
	NUMBER_OF_TANKS = pipes_index - tanks_index - 3
	NUMBER_OF_PIPES = pumps_index - pipes_index - 3
	NUMBER_OF_PUMPS = valves_index - pumps_index - 3
	NUMBER_OF_VALVES = tags_index - valves_index - 3

	NUMBER_OF_ELEMENTS = [NUMBER_OF_JUNCTIONS, NUMBER_OF_RESERVOIRS, NUMBER_OF_TANKS, NUMBER_OF_PIPES, NUMBER_OF_PUMPS, NUMBER_OF_VALVES]

	#This section is to get the dataframe for the junction information
	junction_index += 2
	node_list = list()
	for i in xrange(0,NUMBER_OF_JUNCTIONS):
		current_line = lines[junction_index+i]
		current_line = list(current_line.split()[:4])
		node_list.append(current_line)
	
	node_input_df = pd.DataFrame(node_list,columns=['id','elevation','demand','pattern'])
	node_input_df[['elevation','demand']] = node_input_df[['elevation','demand']].apply(pd.to_numeric)

	#This section is to get dataframe for pipe information
	pipes_index += 2
	pipe_list = list()
	for i in xrange(0,NUMBER_OF_PIPES):
		current_line = lines[pipes_index+i]
		current_line = list(current_line.split()[:4])
		pipe_list.append(current_line)

	pipe_input_df = pd.DataFrame(pipe_list,columns=['pipe_id','node1','node2','length'])
	pipe_input_df[['length']] = pipe_input_df[['length']].apply(pd.to_numeric)

	# node_input_df gives details about each node in the network
	# pipe_input_df gives details about each pipe in the network

	return(NUMBER_OF_ELEMENTS,node_input_df,pipe_input_df)




def parse_output(file_path, NUMBER_OF_ELEMENTS,leaking_node_id):
	file = open(file_path)

	lines = [line.rstrip('\n') for line in file]
	lines = [' '.join(element.split()) for element in lines]

	file.close()

	NUMBER_OF_NODES = NUMBER_OF_ELEMENTS[0] + NUMBER_OF_ELEMENTS[1] + NUMBER_OF_ELEMENTS[2]
	NUMBER_OF_LINKS = NUMBER_OF_ELEMENTS[3] + NUMBER_OF_ELEMENTS[4] + NUMBER_OF_ELEMENTS[5]

	result_beginning_index = lines.index('Node Results at 0:00:00 hrs:')	

	node_first_time_store = list()   #These 4 lists store the first iteration of node and link (normal)
	link_first_time_store = list()	# followed by the second iteration of node and link (abnormal)
	node_second_time_store = list()	# This can then be compared to find difference / change in pressure and the flow rates
	link_second_time_store = list()
	result_beginning_index += 5

	for i in xrange(0,NUMBER_OF_NODES):
		current_line = lines[result_beginning_index+i]
		current_line = list(current_line.split()[:4])
		# current_line[:1] = map(int,current_line[:1])
		current_line[1:4] = map(float,current_line[1:4])
		node_first_time_store.append(current_line)

	result_beginning_index += NUMBER_OF_NODES
	result_beginning_index += 7

	for i in xrange(0,NUMBER_OF_LINKS):
		current_line = lines[result_beginning_index+i]
		current_line = list(current_line.split()[:4])
		# current_line[:1] = map(int,current_line[:1])
		current_line[1:4] = map(float,current_line[1:4])
		link_first_time_store.append(current_line)

	result_beginning_index += NUMBER_OF_LINKS
	result_beginning_index += 7

	for i in xrange(0,NUMBER_OF_NODES):
		current_line = lines[result_beginning_index+i]
		current_line = list(current_line.split()[:4])
		# current_line[:1] = map(int,current_line[:1])
		current_line[1:4] = map(float,current_line[1:4])
		node_second_time_store.append(current_line)

	result_beginning_index += NUMBER_OF_NODES
	result_beginning_index += 7

	for i in xrange(0,NUMBER_OF_LINKS):
		current_line = lines[result_beginning_index+i]
		current_line = list(current_line.split()[:4])
		# current_line[:1] = map(int,current_line[:1])
		current_line[1:4] = map(float,current_line[1:4])
		link_second_time_store.append(current_line)

	result_beginning_index += NUMBER_OF_LINKS
	result_beginning_index += 7

	node_first_time_store = pd.DataFrame(node_first_time_store,columns = ['id','demand','head','pressure'])
	node_second_time_store = pd.DataFrame(node_second_time_store,columns = ['id','demand','head','pressure'])
	link_first_time_store = pd.DataFrame(link_first_time_store,columns = ['pipe_id','flow','velocity','headloss'])
	link_second_time_store = pd.DataFrame(link_second_time_store,columns = ['pipe_id','flow','velocity','headloss'])

	##################################################################################################################
	
	#USE THIS ONLY IF YOU NEED THE FLOWDATA FILES FOR BREZO

	# brezo_lines = [line.rstrip('\n') for line in open('./brezo_related/flowdata52417.dat')]

	# leaking_node_index = node_second_time_store[node_second_time_store['id']==leaking_node_id].index.tolist()
	# leaking_node_index = leaking_node_index[0]
	
	# first_pressure_compute = node_second_time_store['pressure'][leaking_node_index]
	
	# node_third_time_store = list()
	# link_third_time_store = list()

	# ######  THIRD TIME FOR THE SAKE OF BREZO ########
	# for i in xrange(0,NUMBER_OF_NODES):
	# 	current_line = lines[result_beginning_index+i]
	# 	current_line = list(current_line.split()[:4])
	# 	# current_line[:1] = map(int,current_line[:1])
	# 	current_line[1:4] = map(float,current_line[1:4])
	# 	node_third_time_store.append(current_line)

	# result_beginning_index += NUMBER_OF_NODES
	# result_beginning_index += 7
	
	# for i in xrange(0,NUMBER_OF_LINKS):
	# 	current_line = lines[result_beginning_index+i]
	# 	current_line = list(current_line.split()[:4])
	# 	# current_line[:1] = map(int,current_line[:1])
	# 	current_line[1:4] = map(float,current_line[1:4])
	# 	link_third_time_store.append(current_line)

	# result_beginning_index += NUMBER_OF_LINKS
	# result_beginning_index += 7

	# node_third_time_store = pd.DataFrame(node_third_time_store,columns = ['id','demand','head','pressure'])
	# link_third_time_store = pd.DataFrame(link_third_time_store,columns = ['pipe_id','flow','velocity','headloss'])

	# second_pressure_compute = node_third_time_store['pressure'][leaking_node_index]

	# first_flow_compute = 300*(first_pressure_compute**3)
	# second_flow_compute = 300*(second_pressure_compute**3)

	# # first_flow_compute = math.ceil(first_flow_compute * (0.3048**3))
	# # second_flow_compute = math.ceil(second_flow_compute * (0.3048**3))

	# split_line = brezo_lines[3].split()
	# split_line[-1] = str(first_flow_compute)
	# brezo_lines[3] = str(split_line[0]) + str('  ') + str(split_line[1]) + str(' ') + str(split_line[2]) + str(' ') + str(split_line[3]) + str(' ') + str(split_line[4]) + str(' ') + str(split_line[5]) + str(' ') + str(split_line[6]) + str('  ') + str(split_line[7])
	
	# split_line = brezo_lines[4].split()
	# split_line[-1] = str(second_flow_compute)
	# brezo_lines[4] = str(split_line[0]) + str('  ') + str(split_line[1]) + str(' ') + str(split_line[2]) + str(' ') + str(split_line[3]) + str(' ') + str(split_line[4]) + str(' ') + str(split_line[5]) + str(' ') + str(split_line[6]) + str('  ') + str(split_line[7])

	# output_string = str('./brezo_related/data/') + str(leaking_node_id) + str('.dat')
	# brezo_output = open(output_string, 'w')
	# for line in brezo_lines:
 #  		brezo_output.write("%s\n" % line)

 #  	brezo_output.close()

	###################################################################################################################
	

	return(node_first_time_store,node_second_time_store,link_first_time_store,link_second_time_store)
	

def isConnected(node_input_df,pipe_input_df,node_first_time_store,node_second_time_store,link_first_time_store,link_second_time_store):
	
	unique_node_id = list(node_input_df['id'])
	isConnected_list = list()
	connected_distance = list()
	connected_velocity = list()
	connected_time = list()

	for i in xrange(0,len(unique_node_id)):
		current_node = unique_node_id[i]
		current_node_rows = pipe_input_df[pipe_input_df['node1'] == current_node].index.tolist()	# finding the row numbers containing current node
		
		current_node_list = list()	# initializing a list to store the other nodes to which current node is connected immediately
		current_node_distance = list() # initializing a list to store the distance to other immediate nodes for current node
		current_node_velocity = list()	#initializing list to store velocity of pipe between the current node and this node
		current_node_time = list()		#initializing list to store the propagation time between current node and this node

		for j in xrange(0,len(current_node_rows)):
			row_number = current_node_rows[j]
			temp_node = pipe_input_df['node2'][row_number]	#computing node connection info
			if temp_node not in unique_node_id:
				continue
			temp_distance = pipe_input_df['length'][row_number]	#computing node distance info

			temp_pipe = pipe_input_df['pipe_id'][row_number]	#computing node pipe info
			pipe_row_number = link_second_time_store[link_second_time_store['pipe_id'] == temp_pipe].index.tolist()
			temp_velocity = link_second_time_store['velocity'][pipe_row_number[0]]
			
			if temp_velocity == 0:
				temp_velocity = 0.1
			if temp_velocity != 0:
				temp_time = temp_distance/temp_velocity
				temp_time = int(math.ceil(temp_time))
			


			current_node_list.insert(len(current_node_list),temp_node)
			current_node_distance.insert(len(current_node_distance),temp_distance)
			current_node_velocity.insert(len(current_node_velocity),temp_velocity)
			current_node_time.insert(len(current_node_time),temp_time)
		
		isConnected_list.append(current_node_list)
		connected_distance.append(current_node_distance)
		connected_velocity.append(current_node_velocity)
		connected_time.append(current_node_time)

	# unique_node_id returns the unique node id's
	# isConnected_list returns the node id's that the current node index is connected to (in the direction of flow)
	# connected_distance/velocity/time is the corresponding distance, velocity and time 

	return(unique_node_id,isConnected_list,connected_distance,connected_velocity,connected_time)



def leakMatrixCreation(leaking_node_id,unique_node_id,isConnected_list,connected_distance,connected_velocity,connected_time,node_first_time_store,node_second_time_store):
	leaking_node_index = unique_node_id.index(leaking_node_id)
	
	distance_array = [float('inf') for i in range(len(unique_node_id))]
	distance_array[leaking_node_index] = 0
	demand_shortage_array = [float('inf') for i in range(len(unique_node_id))]
	original_demand = node_first_time_store['demand'][leaking_node_index]
	new_demand = node_second_time_store['demand'][leaking_node_index]
	demand_shortage_array[leaking_node_index] = original_demand - new_demand
	detection_time_array = [float('inf') for i in range(len(unique_node_id))]
	detection_time_array[leaking_node_index] = 0
	detection_capability_array = [0 for i in range(len(unique_node_id))]
	detection_capability_array[leaking_node_index] = 1

	stack = list()
	stack.insert(0,leaking_node_index)
	visited_array = [False for i in range(len(unique_node_id))]

	# Do a DFS from the node in which leak has been created. Check in its connected pipes if a pressure difference can be detected
	# Repeat this until the effect of the leak can no longer be detected. For each introduced leak, build a vector giving details 
	# of the extent of the leak's effects

	while len(stack) > 0:
		parent_node_index = stack.pop()
		if visited_array[parent_node_index] == True:
			continue
		visited_array[parent_node_index] = True

		for j in xrange(0,len(isConnected_list[parent_node_index])):
			current_node_id = isConnected_list[parent_node_index][j]
			current_node_index = unique_node_id.index(current_node_id)
			
			original_pressure = node_first_time_store['pressure'][current_node_index]
			new_pressure = node_second_time_store['pressure'][current_node_index]

			if original_pressure > (1.02 * new_pressure):		#modelling pressure drop as indication of leak affectation
				stack.insert(0,current_node_index)

				original_demand = node_first_time_store['demand'][current_node_index]
				new_demand = node_second_time_store['demand'][current_node_index]
				demand_shortage = original_demand - new_demand    #getting demand shortage in negative so as to use min function
				demand_shortage_array[current_node_index] = min(demand_shortage,demand_shortage_array[current_node_index])

				distance_array[current_node_index] = min(connected_distance[parent_node_index][j] + distance_array[parent_node_index],distance_array[current_node_index])
				detection_time_array[current_node_index] = min(connected_time[parent_node_index][j] + detection_time_array[parent_node_index], detection_time_array[current_node_index])
				detection_capability_array[current_node_index] = 1

	
	return(distance_array,demand_shortage_array,detection_time_array,detection_capability_array)



def mobileMatrixCreation(mobile_node_id,unique_node_id,isConnected_list,connected_time):
	mobile_node_index = unique_node_id.index(mobile_node_id)
	mobile_traversal_array = [float(0) for i in range(len(unique_node_id))]   # Set 0 since we are measuring probability of traversing to a downstream node - current node's own traversal is set to 0
	mobile_traversal_time_array = [float('inf') for i in range(len(unique_node_id))]  # Corresponding time for the mobile sensor to traverse to a downstream node. Function of flow rates. 
	
	current_node_connections = isConnected_list[mobile_node_index]
	current_node_connection_times = connected_time[mobile_node_index]
	if len(current_node_connections)!=0:
		for i in xrange(0,len(current_node_connections)):
			connected_node_index = unique_node_id.index(current_node_connections[i])
			mobile_traversal_array[connected_node_index] = float(1/len(current_node_connections))
			mobile_traversal_time_array[connected_node_index] = current_node_connection_times[i]
	return(mobile_traversal_array,mobile_traversal_time_array)



# NUMBER_OF_ELEMENTS,node_input_df,pipe_input_df = parse_input("../Data/final_input.inp")

# node_first_time_store,node_second_time_store,link_first_time_store,link_second_time_store = parse_output("../Data/final_output.txt", NUMBER_OF_ELEMENTS,1)

# unique_node_id,isConnected_list,connected_distance,connected_velocity,connected_time = isConnected(node_input_df,pipe_input_df,node_first_time_store,node_second_time_store,link_first_time_store,link_second_time_store)

# distance_array,demand_shortage_array,detection_time_array,detection_capability_array = leakMatrixCreation(3,unique_node_id,isConnected_list,connected_distance,connected_velocity,connected_time,node_first_time_store,node_second_time_store)

# mobile_traversal_array,mobile_traversal_time_array = mobileMatrixCreation("2",unique_node_id,isConnected_list,connected_time)

