import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import math


read_wssc = "../Data/UCI_WSSC_Pressure_Zone_EPANET.inp"
read_richmond = "../Data/Richmond.inp"
read_colorado = "../Data/coloradosprings.inp"


def parse_input(file_path,variable):
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

	NUMBER_OF_JUNCTIONS = reservoir_index - junction_index - variable
	NUMBER_OF_RESERVOIRS = tanks_index - reservoir_index - variable
	NUMBER_OF_TANKS = pipes_index - tanks_index - variable
	NUMBER_OF_PIPES = pumps_index - pipes_index - variable
	NUMBER_OF_PUMPS = valves_index - pumps_index - variable
	NUMBER_OF_VALVES = tags_index - valves_index - variable

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


NUMBER_OF_ELEMENTS,node_input_df,pipe_input_df = parse_input(read_richmond,2)

print node_input_df['demand'].sum()
print pipe_input_df['length'].sum()

