import pandas as pd
import numpy as np
import os
from numpy import inf
from numpy import random
import csv

def parse_input(input_file):
    read_input = open(input_file,'r')
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

    detectionCapability = np.genfromtxt("../Output/detectionCapability.csv", delimiter=',')

    traversalCapability = np.genfromtxt("../Output/traversalCapability.csv",delimiter=",")

    traversalTime = np.genfromtxt("../Output/traversalTime.csv",delimiter=",")

    detection_weight_number = []      # Array to store the number of nodes detectable by each node to obtain weight later
    for i in xrange(0,len(detectionCapability)):
        current_line = detectionCapability[i]
        detection_number = [j for j,v in enumerate(current_line) if v==1]
        detection_number = len(detection_number)
        detection_weight_number.append(detection_number)

    detectionTime = np.genfromtxt("../Output/detectionTime.csv", delimiter=',')
    impactMatrix = pd.read_csv("../Output/final_impact_matrix.csv")
    impactMatrix = impactMatrix.values
    impactMatrix = [row[1:] for row in impactMatrix]
    triangle_score = np.genfromtxt("../Output/final_triangle_score.csv",delimiter=",",skip_header=1)
    
    # print(detectionCapability)
    # print(detectionTime)
    # print(impactMatrix)
    # print(triangle_score)
    # print traversalCapability[1]
    # print len(traversalCapability[1])
    # print traversalCapability[:,1]
    # print len(traversalCapability[:,1])

    # print traversalTime
    return(unique_node_id,detectionCapability,detectionTime,triangle_score,impactMatrix,detection_weight_number, traversalCapability, traversalTime)


# The below function takes as input the node for which the utility score is to be computed
# It identifies the impacted triangles and then computes the product of triangle score * impact(triangle)
# for each of the impacted triangles and returns the score
def computeTriangleImpactProduct(impact_matrix,triangle_score,node_index):
    score = 0
    impacted_indices = [j for j,v in enumerate(impact_matrix[node_index]) if v > 0]
    for index in impacted_indices:
        score = score + (impact_matrix[node_index][index] * triangle_score[index])
    return(score)


def numberOfMobileSensors(unique_node_id,current_sensor_id,traversalCapability):
    ''' Function to return the number of mobile sensors that should be deployed at a junction
    '''
    current_sensor_index = unique_node_id.index(current_sensor_id)

    traversal_capability_current_sensor = traversalCapability[current_sensor_index]
    traversal_capability_current_sensor = [v for j,v in enumerate(traversal_capability_current_sensor) if v > 0]

    traversal_capability_current_sensor.sort()
    traversal_capability_ratio = []

    for i in xrange(0,len(traversal_capability_current_sensor)):
        traversal_capability_ratio.append(float( (i+1) / traversal_capability_current_sensor[i]))

    max_ratio = max(traversal_capability_ratio)
    max_ratio_index = traversal_capability_ratio.index(max_ratio)
    number_of_mobile_sensors = traversal_capability_current_sensor[max_ratio_index]

    return number_of_mobile_sensors

def computeUtility(unique_node_id,current_sensor_id,detectionCapability,detectionTime,traversalCapability,traversalTime,impactMatrix,static_sensor_cost,mobile_sensor_cost,triangle_score,
    mobile_sensor_deployment_set, shortest_detection_time_set,static_sensor_placed,mobile_sensor_placed):
    ''' Function that computes the utility score of adding a sensor. 
    Utility of adding a static sensor = Sum(Impact_ j / DetectionTime_ j) / CostofStatic , where j is iterated over the detectable leaks
    Utility of adding a mobile sensor = Sum(Impact_ j / DetectionTime_ j + TraversalTime_ j) / CostofMobile * Number of sensors , where j is iterated over the detectable leaks
    '''
    current_sensor_index = unique_node_id.index(current_sensor_id)
    
    nodes_detected_by_current_sensor = detectionCapability[current_sensor_index]
    nodes_detected_by_current_sensor = [j for j,v in enumerate(nodes_detected_by_current_sensor) if v == 1]

    detection_times_of_current_sensor = detectionTime[current_sensor_index]
    detection_times_of_current_sensor = detection_times_of_current_sensor[nodes_detected_by_current_sensor]  # Get the detection times of only the leaks detectable by current sensor

    traversal_times_of_current_sensor = traversalTime[current_sensor_index]
    traversal_times_of_current_sensor = traversal_times_of_current_sensor[nodes_detected_by_current_sensor]
    shortest_detection_time_set = shortest_detection_time_set[nodes_detected_by_current_sensor]

    final_static_utility_score = -1
    final_mobile_utility_score = -1

    if current_sensor_id not in static_sensor_placed:
        final_static_utility_score = 0
        for i in xrange(0,len(nodes_detected_by_current_sensor)):
            detected_node = nodes_detected_by_current_sensor[i]
            # Only consider if it can detect leaks faster than existing placed nodes 
            if detection_times_of_current_sensor[i] >= shortest_detection_time_set[i]:
                continue
            detected_node_impact_score = float(computeTriangleImpactProduct(impactMatrix,triangle_score,detected_node))
            if detection_times_of_current_sensor[i] != 0:
                detected_node_impact_score = detected_node_impact_score / detection_times_of_current_sensor[i]
            final_static_utility_score = final_static_utility_score + detected_node_impact_score
            
        final_static_utility_score = float(final_static_utility_score / static_sensor_cost)  # Utility of placing a static sensor

    if current_sensor_id in mobile_sensor_deployment_set and current_sensor_id not in mobile_sensor_placed:
        final_mobile_utility_score = 0
        number_of_mobile_sensors = numberOfMobileSensors(unique_node_id,current_sensor_id,traversalCapability)
        for i in xrange(0,len(nodes_detected_by_current_sensor)):
            detected_node = nodes_detected_by_current_sensor[i]
            # Only consider if it can detect leaks faster than existing placed nodes 
            if detection_times_of_current_sensor[i] >= shortest_detection_time_set[i]:
                continue
            detected_node_impact_score = float(computeTriangleImpactProduct(impactMatrix,triangle_score,detected_node))
            mobile_sensor_total_time = traversal_times_of_current_sensor[i] + shortest_detection_time_set[i]  # Check this part
            if mobile_sensor_total_time == 0:
                continue
            detected_node_impact_score = detected_node_impact_score / mobile_sensor_total_time
            final_mobile_utility_score = final_mobile_utility_score + detected_node_impact_score

        final_mobile_utility_score = float(final_mobile_utility_score / (mobile_sensor_cost * number_of_mobile_sensors))

    if final_static_utility_score == -1 and final_mobile_utility_score == -1:
        final_utility_score = -100
        final_node_result = 1
        final_node_number = 0
    elif final_static_utility_score > final_mobile_utility_score:
        final_utility_score = final_static_utility_score
        final_node_result = 1
        final_node_number = 0
    else:
        final_utility_score = final_mobile_utility_score
        final_node_result = 0
        final_node_number = number_of_mobile_sensors



    return final_utility_score, final_node_result, final_node_number

def hybridAlgorithm(unique_node_id, detectionCapability, detectionTime, traversalCapability, traversalTime, impactMatrix, triangle_score):
    ''' Hybrid algorithm function that returns the final sensor placement locations. For mobile sensor locations it also returns
    the number of sensors deployed '''


    isCovered_list = [False] * len(unique_node_id)
    static_sensor_placed = []
    mobile_sensor_placed = []
    mobile_number_deployed = []

    mobile_sensor_deployment_set = []

    BUDGET = 100000
    static_sensor_cost = 6
    mobile_sensor_cost = 1

    uncovered_indices = [index for index,v in enumerate(isCovered_list) if v == False]
    node_shortest_detection_time_list = [float("inf")] * len(unique_node_id)
    node_shortest_detection_time_list = np.asarray(node_shortest_detection_time_list,dtype=np.float32)

    while BUDGET > 0 and len(uncovered_indices) > 0: # Stopping conditions are that either budget is exhausted or network has been covered
        print len(uncovered_indices)
        utility_score = []
        result_flag = []
        deployed_number = []
        for i in xrange(0,len(unique_node_id)):
            # print i
            current_node_utility, current_node_result, current_node_number = computeUtility(unique_node_id,unique_node_id[i],detectionCapability,detectionTime,
                traversalCapability,traversalTime,impactMatrix,static_sensor_cost,mobile_sensor_cost,triangle_score,mobile_sensor_deployment_set,
                node_shortest_detection_time_list, static_sensor_placed,mobile_sensor_placed)
            
            nodes_detected_by_current_sensor = detectionCapability[i]
            nodes_detected_by_current_sensor = [j for j,v in enumerate(nodes_detected_by_current_sensor) if v == 1]
            unique_detection_score = len([x for x in nodes_detected_by_current_sensor if isCovered_list[x] == False])
            current_node_utility = current_node_utility + unique_detection_score
            # if isCovered_list[i] == True:
            #     current_node_utility = -100
            #     current_node_result = 1
            #     current_node_number = 0
            utility_score.append(current_node_utility)
            result_flag.append(current_node_result)
            deployed_number.append(current_node_number)

        max_utility = max(utility_score)
        print "Max utility score", max_utility
        max_utility_index = utility_score.index(max_utility) # Get the first index of the junction with max utility

        if result_flag[max_utility_index] == 1:  # If the max utility is to place a static sensor
            static_sensor_placed.append(unique_node_id[max_utility_index])
            
            BUDGET = BUDGET - static_sensor_cost

            nodes_detected_by_max_utility = detectionCapability[max_utility_index]
            nodes_detected_by_max_utility = [j for j,v in enumerate(nodes_detected_by_max_utility) if v == 1]
            detection_times_of_max_utility = detectionTime[max_utility_index]

            for node in nodes_detected_by_max_utility:
                isCovered_list[node] = True
                node_shortest_detection_time_list[node] = min(node_shortest_detection_time_list[node],detection_times_of_max_utility[node])
            isCovered_list[max_utility_index] = True #Setting current placed point = true


            # Once a static sensor has been placed, it is capable of detecting leaks at a subset of locations 
            # The mobile sensors capable of traversing to those locations can thus be unlocked 

            for node in nodes_detected_by_max_utility: # Need to add the unlocked mobile sensor information to the deployment set
                traversal_column = traversalCapability[:,node]
                required_mobile_rows = [j for j,v in enumerate(traversal_column) if v > 0]
                for mobile_row in required_mobile_rows:
                    mobile_sensor_deployment_set.append(unique_node_id[mobile_row])
            print "Placed static at " , max_utility_index


        if result_flag[max_utility_index] == 0:
            mobile_sensor_placed.append(unique_node_id[max_utility_index])
            mobile_number_deployed.append(deployed_number[max_utility_index])

            BUDGET = BUDGET - (deployed_number[max_utility_index] * mobile_sensor_cost)

            nodes_detected_by_max_utility = detectionCapability[max_utility_index]
            nodes_detected_by_max_utility = [j for j,v in enumerate(nodes_detected_by_max_utility) if v == 1]
            detection_times_of_max_utility = detectionTime[max_utility_index]

            for node in nodes_detected_by_max_utility:
                isCovered_list[node] = True
                # node_shortest_detection_time_list[node] = min(node_shortest_detection_time_list[node],detection_times_of_max_utility[node])
            isCovered_list[max_utility_index] = True #Setting current placed point = true 

            print "placed mobile at", max_utility_index

        uncovered_indices = [index for index,v in enumerate(isCovered_list) if v == False]           

    return mobile_sensor_placed,static_sensor_placed,isCovered_list

if __name__ == "__main__":
    input_file = "../Data/final_input.inp"
    unique_node_id, detectionCapability, detectionTime, triangle_score, impactMatrix, detection_weight_number, traversalCapability, traversalTime = parse_input(input_file)

    mobile_sensor_placed,static_sensor_placed,isCovered_list = hybridAlgorithm(unique_node_id, detectionCapability, detectionTime, traversalCapability, traversalTime, impactMatrix, triangle_score)
    print mobile_sensor_placed
    print len(mobile_sensor_placed)
    print static_sensor_placed
    print len(static_sensor_placed)
    # print isCovered_list
    # outputfile = open("static_sensor_locations.csv","w")
    # for item in static_sensor_placed:
    #     outputfile.write("%s\n" % item)
    # outputfile = open("mobile_sensor_locations.csv","w")
    # for item in mobile_sensor_placed:
    #     outputfile.write("%s\n" % item)