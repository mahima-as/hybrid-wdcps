import numpy
import csv
from collections import defaultdict

def find(lst, key, value):
    for i, dic in enumerate(lst):
        if dic[key] == value:
            return i

			
def read_EPANET_Input (path, net_name):
	network = {"vertices": [], "edges": []}
	vertex_types = ["JUNCTIONS", "RESERVOIRS", "TANKS", "EMITTERS"]
	edge_types = ["PIPES", "PUMPS", "VALVES"]
	######## Define file names #########
	input_file_name = path + "\\" + net_name + ".inp"
	flow_file_name = path + "\\" + net_name + "_EdgeFlow_7am.txt"
	######## Read the input file #########
	f = open(input_file_name, "r")
	contents = f.readlines()
	line_no = 0
	while line_no < len(contents):
		line = contents[line_no]
		if any(t in line for t in vertex_types):
			line_no = line_no+2
			line = contents[line_no]
			line_parts = line.split()
			while len(line_parts) > 0:
				vertexID = line_parts[0]
				network["vertices"].append({"id": vertexID})
				line_no = line_no+1
				line = contents[line_no]
				line_parts = line.split()
		if any(t in line for t in edge_types):
			line_no = line_no+2
			line = contents[line_no]
			line_parts = line.split()
			while len(line_parts) > 0:
				edgeID = line_parts[0]
				network["edges"].append({"id": line_parts[0], "end1": line_parts[1], "end2": line_parts[2]})
				line_no = line_no+1
				line = contents[line_no]
				line_parts = line.split()
		line_no = line_no + 1
	print network
	
	f = open(flow_file_name, "r")
	contents = f.readlines()
	line_no = 4
	while line_no < len(contents):
		line = contents[line_no]
		line_parts = line.split()
		while len(line_parts) > 0:
			print line_parts
			edgeID = line_parts[1]
			edge_index = find(network["edges"], "id", edgeID)
			network["edges"][edge_index].update({"flow":float(line_parts[2])})
			line_no = line_no+1
			if line_no == len(contents):
				break
			line = contents[line_no]
			line_parts = line.split()
	print network
	
	
	
read_EPANET_Input("C:\\Users\\mahima.as\\Documents\\Github\\hybrid-wdcps\\deployment-algorithm\\pure-mobile", "Net1")