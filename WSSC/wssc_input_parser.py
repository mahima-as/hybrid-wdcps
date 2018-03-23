import pandas as pd
import numpy as np
import os
from numpy import inf
from numpy import random
import csv

input_file = "../data/UCI_WSSC_Pressure_Zone_EPANET.inp"


# function that returns the index of the next header to demarcate ending of current section in the file

def find_first_greatest_index(lines,indices_of_headers,index):
	first_greatest_index = np.where(indices_of_headers > index)
	if first_greatest_index[0].size == 0:
		first_greatest_index = len(lines) - 1
	else:
		first_greatest_index = indices_of_headers[first_greatest_index[0][0]]

	return first_greatest_index


# Main Function that parses input EPANET file to obtain pressure and flowrate information easily 

def parse_input(input_file):
	with open(input_file,'r') as out:
		lines = out.readlines()
	lines = filter(lambda x : x.strip(),lines) # Remove empty lines
	lines = [line.rstrip('\r\n') for line in lines] 
	# lines = [element.replace(' ','') for element in lines]
	lines = [element.replace('\t',' ') for element in lines]
	print(lines)
	indices_of_headers = np.empty(0,dtype=int)
	# Getting the row number of all headers that can be then used to get individual information of junctions, reservoirs, etc

	for i in range(0,len(lines)):
		if '[' in lines[i]:
			indices_of_headers = np.append(indices_of_headers,i)

	junction_index = lines.index('[JUNCTIONS]')
	junction_ending_index = find_first_greatest_index(lines,indices_of_headers,junction_index)
	junction_index += 2
	number_of_junctions = junction_ending_index - junction_index	
	node_list = list()
	for i in xrange(0,number_of_junctions):
		current_line = lines[junction_index+i]
		current_line = list(current_line.split()[:4])
		node_list.append(current_line)
		
	node_input_df = pd.DataFrame(node_list,columns=['id','elevation','demand','pattern'])
	unique_node_id = list(node_input_df['id'])

	print(node_input_df)
	reservoir_index = lines.index('[RESERVOIRS]')




parse_input(input_file)
