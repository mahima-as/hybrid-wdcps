import numpy
import csv
from collections import defaultdict
from helpers import find

			
def read_EPANET_Input (path, net_name):
	network = {"vertices": [], "edges": []}
	vertex_types = ["JUNCTIONS", "RESERVOIRS", "TANKS", "EMITTERS"]
	edge_types = ["PIPES", "PUMPS", "VALVES"]
	######## Define file names #########
	input_file_name = path + net_name + ".inp"
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
				network["vertices"].append({"id": vertexID, "children": [], "parents": []})
				line_no = line_no+1
				line = contents[line_no]
				line_parts = line.split()
		if any(t in line for t in edge_types):
			line_no = line_no+2
			line = contents[line_no]
			line_parts = line.split()
			while len(line_parts) > 0:
				edgeID = line_parts[0]
				end1 = line_parts[1]
				end2 = line_parts[2]
				network["edges"].append({"id": line_parts[0], "end1": end1, "end2": end2})
				line_no = line_no+1
				line = contents[line_no]
				line_parts = line.split()
		line_no = line_no + 1
	
	return network
	
def read_EPANET_Flows (network, path, net_name, hour):
	flow_file_name = path + net_name + "_EdgeFlow_" + str(hour) + "am.txt"
	f = open(flow_file_name, "r")
	contents = f.readlines()
	line_no = 4
	while line_no < len(contents):
		line = contents[line_no]
		line_parts = line.split()
		while len(line_parts) > 0:
			edgeID = line_parts[1]
			edge_index = find(network["edges"], "id", edgeID)
			flow = float(line_parts[2])
			end1 = network["edges"][edge_index]["end1"]
			end2 = network["edges"][edge_index]["end2"]
			vertex_index_1 = find(network["vertices"], "id", end1)
			vertex_index_2 = find(network["vertices"], "id", end2)
			
			if(flow < 0):
				network["edges"][edge_index].update({"flow": -1*flow, "end1": end2, "end2": end1})
				children = network["vertices"][vertex_index_2]["children"]
				parents = network["vertices"][vertex_index_1]["parents"]
				children.append(network["vertices"][vertex_index_1]["id"])
				parents.append(network["vertices"][vertex_index_2]["id"])
			else:
				network["edges"][edge_index].update({"flow": flow})
				children = network["vertices"][vertex_index_1]["children"]
				parents = network["vertices"][vertex_index_2]["parents"]
				children.append(network["vertices"][vertex_index_2]["id"])
				parents.append(network["vertices"][vertex_index_1]["id"])
			line_no = line_no+1
			if line_no == len(contents):
				break
			line = contents[line_no]
			line_parts = line.split()
	return network