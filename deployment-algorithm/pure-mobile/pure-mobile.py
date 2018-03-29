import numpy
import csv


def read_EPANET_Input (path, net_name):
	vertex_types = ["JUNCTIONS", "RESERVOIRS", "TANKS", "EMITTERS"]
	edge_types = ["PIPES", "PUMPS", "VALVES"]
	######## Define file names #########
	input_file_name = path + "\\" + net_name + ".inp"
	flow_file_name = path + "\\" + net_name + "_EdgeFlow_7am"
	######## Read the input file #########
	f = open(input_file_name, "r")
	contents = f.readlines()
	for i in range(0, len(contents)):
		line = contents[i]
		if any(t in line for t in vertex_types):
			print contents[i+1]
			i = i+1

read_EPANET_Input("C:\\Users\\mahima.as\\Documents\\Github\\hybrid-wdcps\\deployment-algorithm\\pure-mobile", "Net1")