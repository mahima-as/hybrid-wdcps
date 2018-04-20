import numpy
import csv
from collections import defaultdict
from EPANET_input import read_EPANET_Input, read_EPANET_Flows
from helpers import find, count_less_than, find_min_index, indices_less_than


def read_vector_from_file (path, net_name):
	input_file_name = path + net_name + ".csv"
	f = open(input_file_name, "r")
	contents = f.readlines()
	vec = numpy.zeros(shape=(int(contents[0])))
	line_no = 1
	while line_no < len(contents):
		vec[line_no-1] = float(contents[line_no])
		line_no = line_no + 1
	return vec


def get_P (network):
	num_vertices = len(network["vertices"])
	P = numpy.zeros(shape=(num_vertices, num_vertices))
	total_out = numpy.zeros(num_vertices)
	edges = network["edges"]
	for edge in edges:
		end1 = edge["end1"]
		end1_index = find(network["vertices"], "id", end1)
		total_out[end1_index] = total_out[end1_index] + edge["flow"]
	for edge in edges:
		end1 = edge["end1"]
		end1_index = find(network["vertices"], "id", end1)
		end2 = edge["end2"]
		end2_index = find(network["vertices"], "id", end2)
		P[end1_index][end2_index] =  edge["flow"] / total_out[end1_index]
	return P
	

def get_T (P):
	num_vertices = len(P)
	M = numpy.identity(num_vertices)
	Mn = M
	while not numpy.all(numpy.equal(Mn, numpy.zeros(shape=(num_vertices, num_vertices)))):
		Mn = numpy.matmul(Mn, P)
		M = M + Mn
	return M


def get_N (T, Dc):
	num_vertices = len(P)
	N = numpy.zeros(shape=(num_vertices, num_vertices))
	for i in range(0, num_vertices):
		for j in range(0, num_vertices):
			if T[i][j] == 0:
				N[i][j] = float("inf")
			elif T[i][j] == 1:
				N[i][j] = 1
			else:
				N[i][j] =  numpy.ceil(numpy.log(1-Dc[j])/numpy.log(1-T[i][j]))
	return N
			

def get_Badness_No_Impact (N, I):
	num_vertices = len(P)
	B = numpy.zeros(shape=(num_vertices, num_vertices))
	for i in range(0, num_vertices):
		for j in range(0, num_vertices):
			if N[i][j] == float("inf"):
				B[i][j] = float("inf")
			else:
				B[i][j] = float(N[i][j])/float(count_less_than(N[i], N[i][j]))
	return B
	

def get_Badness_Harmonic_Impact (N, I):
	num_vertices = len(P)
	B = numpy.zeros(shape=(num_vertices, num_vertices))
	for i in range(0, num_vertices):
		for j in range(0, num_vertices):
			if N[i][j] == float("inf"):
				B[i][j] = float("inf")
			else:
				indices = indices_less_than(N[i], N[i][j])
				impact_total = 0
				for index in indices:
					impact_total = impact_total + 1/(1+I[index])
				B[i][j] = float(N[i][j])/float(impact_total)
	return B
	

def update_N (min, min_i, min_j, N):
	num_vertices = len(N)
	updates = indices_less_than(N[min_i], min)
	for update in updates:
		for i in range(0, num_vertices):
			N[i][update] = float("inf")
	for j in range(0, num_vertices):
		if N[min_i][j] < min:
			N[min_i][j] = float("inf")
		elif not N[min_i][j] == float("inf"):
			N[min_i][j] = N[min_i][j] - min
	return N

	
def pick_sensors(budget, N):
	num_sensors = 0
	num_vertices = len(N)
	S = numpy.zeros(shape=(num_vertices))
	while True:
		B = get_Badness_Harmonic_Impact(N, Impact)
		print("B is")
		print(B)
		print(N)
		minB, min_i, min_j = find_min_index(B)
		print (minB, min_i, min_j)
		min = N[min_i][min_j]
		if min == float("inf"):
			break
		if num_sensors + min <= budget:
			S[min_i] = S[min_i] + min
			num_sensors = num_sensors + min
			N = update_N(min, min_i, min_j, N)
		else:
			S[min_i] = S[min_i] + budget - num_sensors
			break
	return S

	
network = read_EPANET_Input("", "Net1")
network = read_EPANET_Flows (network, "", "Net1", "7")
P = get_P(network)
T = get_T(P)
Dc = read_vector_from_file("", "Net1_dc")
Impact = read_vector_from_file("", "Net1_impact")
N = get_N(T, Dc)

budget = 25

S = pick_sensors(budget, N)
print(S)



