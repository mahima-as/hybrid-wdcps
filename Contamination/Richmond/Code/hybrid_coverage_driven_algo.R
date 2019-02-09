read_input = readLines("../Data/final_input.inp")
read_input = gsub("\\s+"," ",read_input)
read_input = gsub("\t|^\\s+|\\s+$","",read_input)

junction_beginning = (which(read_input == "[JUNCTIONS]")) + 2
junction_ending = which(read_input == "[RESERVOIRS]") - 2
junction_list = read_input[junction_beginning:junction_ending]
node_list = c()
for(i in 1:length(junction_list))
{
	split_line = strsplit(junction_list[i]," ")[[1]]
	node_list = c(node_list,split_line[1])
}
unique_node_id = node_list  # Getting Unique node ID list 

################## Reading the other matrices ##########################################

detectionCapability = read.csv("../Output/detectionCapability1.csv",header=FALSE)

detectionTime = read.csv("../Output/detectionTime.csv",header=FALSE)
traversalCapability = read.csv("../Output/traversalCapability1.csv",header=FALSE)

traversalTime = read.csv("../Output/traversalTime.csv",header=FALSE)
# impactMatrix = as.matrix(read.csv("../Output/final_impact_matrix.csv"))
# triangle_score = as.vector(as.matrix(read.csv("../Output/final_triangle_score.csv")))

########################################################################################## 

# Normalizing the matrices - triangle score, impact matrix, detection time and traversal time  

# triangle_score = (triangle_score - min(triangle_score)) / (max(triangle_score) - min(triangle_score))

# impactMatrix = impactMatrix[,-1]
# colnames(impactMatrix) = NULL
# rownames(impactMatrix) = NULL
# class(impactMatrix) = "numeric"
# impactMatrix = (impactMatrix - min(impactMatrix)) / (max(impactMatrix) - min(impactMatrix))

detectionTimeArray = as.matrix(detectionTime)
class(detectionTimeArray) = "numeric"
detectionTimeArray = as.vector(detectionTimeArray)
detectionTimeArray = detectionTimeArray[which(is.finite(detectionTimeArray) & detectionTimeArray != 0)]
# print(detectionTimeArray)
# print(length(which(detectionTimeArray<0)))
detectionTime = as.matrix(detectionTime)
class(detectionTime) = "numeric"
for(i in 1:length(detectionTime[,1]))
{
	current_row = detectionTime[i,]
	indices = which(is.finite(current_row) & current_row!=0)
	for(j in 1:length(indices))
	{
		current_row[indices[j]] = (current_row[indices[j]] - min(detectionTimeArray)) / (max(detectionTimeArray) - min(detectionTimeArray))
	}
	detectionTime[i,] = current_row
}

traversalTimeArray = as.matrix(traversalTime)
class(traversalTimeArray) = "numeric"
traversalTimeArray = as.vector(traversalTimeArray)
traversalTimeArray = traversalTimeArray[which(is.finite(traversalTimeArray) & traversalTimeArray != 0)]
traversalTime = as.matrix(traversalTime)
class(traversalTime) = "numeric"
for(i in 1:length(traversalTime[,1]))
{
	current_row = traversalTime[i,]
	indices = which(is.finite(current_row) & current_row!=0)
	for(j in 1:length(indices))
	{
		current_row[indices[j]] = (current_row[indices[j]] - min(traversalTimeArray)) / (max(traversalTimeArray) - min(traversalTimeArray))
	}
	traversalTime[i,] = current_row
}
########################################################################################## 
# Function to compute number of mobile sensors to be deployed

numberOfMobileSensors <- function(unique_node_id,current_sensor_id,traversalCapability)
{
	current_sensor_index = which(unique_node_id == current_sensor_id)

	traversal_capability_current_sensor = traversalCapability[current_sensor_index,]
	traversal_capability_current_sensor = traversal_capability_current_sensor[which(traversal_capability_current_sensor > 0)]
	traversal_capability_current_sensor = as.numeric(as.vector(traversal_capability_current_sensor))

	traversal_capability_current_sensor = sort(traversal_capability_current_sensor)
	traversal_capability_ratio = c()

	for(i in 1:length(traversal_capability_current_sensor))
	{
		traversal_capability_ratio = c(traversal_capability_ratio, as.numeric((i+1)/traversal_capability_current_sensor[i]))
	}

	max_ratio_index = which(traversal_capability_ratio == max(traversal_capability_ratio))
	number_of_mobile_sensors = traversal_capability_current_sensor[max_ratio_index]

	return(number_of_mobile_sensors)
}



##########################################################################################
################ Function to compute score as product of impact on triangle and triangle score ################
computeTriangleImpactProduct = function(impactMatrix,triangle_score,node_index)
{
	score = 0
	impacted_indices = which(impactMatrix[node_index,] > 0)
	if(length(impacted_indices) > 0)
	{
		for(i in 1:length(impacted_indices))
		{
			index = impacted_indices[i]
			score = as.numeric(score + as.numeric(impactMatrix[node_index,index] * triangle_score[index]))
		}
	}
	return(score)
}
################################################################################################
# Function to compute the utility of a sensor

computeUtility <- function(unique_node_id,current_sensor_id,detectionCapability,detectionTime,traversalCapability,traversalTime,impactMatrix,
	static_sensor_cost,mobile_sensor_cost,triangle_score,mobile_sensor_deployment_set,node_shortest_detection_time_set,static_sensor_placed,mobile_sensor_placed)
{
	current_sensor_index = which(unique_node_id==current_sensor_id)
	nodes_detected_by_current_sensor = detectionCapability[current_sensor_index,]
	nodes_detected_by_current_sensor = which(nodes_detected_by_current_sensor==1)
	detection_times_of_current_sensor = detectionTime[current_sensor_index,]
	detection_times_of_current_sensor = detection_times_of_current_sensor[nodes_detected_by_current_sensor]

	traversal_times_of_current_sensor = traversalTime[current_sensor_index,]
	traversal_times_of_current_sensor = traversal_times_of_current_sensor[nodes_detected_by_current_sensor]

	node_shortest_detection_time_set = node_shortest_detection_time_set[nodes_detected_by_current_sensor]

	final_static_utility_score = -1
	final_mobile_utility_score = -1
	final_utility_score = 0
	final_node_result = 0
	final_node_number = 0
	# print("INSIDE UTILITY")
	# print(mobile_sensor_deployment_set)
	# print(current_sensor_id)
	number_of_mobile_sensors = numberOfMobileSensors(unique_node_id,current_sensor_id,traversalCapability)
	mobile_sensor_deployment_set = mobile_sensor_deployment_set[-which(is.na(mobile_sensor_deployment_set))]
	
	if(!(current_sensor_id %in% static_sensor_placed))
	{
		final_static_utility_score = 0
		for(i in 1:length(nodes_detected_by_current_sensor))
		{
			detected_node = nodes_detected_by_current_sensor[i]

			# Only consider the detected node if it is detected faster by current node than existing placed nodes
			if(is.finite(node_shortest_detection_time_set[i]))
			{
				if(detection_times_of_current_sensor[i] >= node_shortest_detection_time_set[i])
					next
			}
			detected_node_impact_score = as.numeric(computeTriangleImpactProduct(impactMatrix,triangle_score,detected_node))
			if(detection_times_of_current_sensor[i]!=0)
			{
				detected_node_impact_score = detected_node_impact_score / detection_times_of_current_sensor[i]
			}
			final_static_utility_score = final_static_utility_score + detected_node_impact_score
		}
		final_static_utility_score = as.numeric(final_static_utility_score / static_sensor_cost) # Utility of placing a static sensor
	}
	if((current_sensor_id %in% mobile_sensor_deployment_set) && !(current_sensor_id %in% mobile_sensor_placed))
	{
		final_mobile_utility_score = 0
		
		# print("NUMBER OF MOVILE")
		# print(number_of_mobile_sensors)
		for(i in 1:length(nodes_detected_by_current_sensor))
		{
			detected_node = nodes_detected_by_current_sensor[i]
			# We consider the mobile node traversal impact always since scenario is that one of the static sensors detects the issue 
			# and the mobile nodes are deployed from wherever. Need not be the same location as the static. 
			# However, if the current node cannot be detected yet, then we dont consider it 

			if(!(is.finite(node_shortest_detection_time_set[i])))
				next

			detected_node_impact_score = as.numeric(computeTriangleImpactProduct(impactMatrix,triangle_score,detected_node))
			mobile_sensor_total_time = traversal_times_of_current_sensor[i] + node_shortest_detection_time_set[i]
			# mobile_sensor_total_time = traversal_times_of_current_sensor[i]
			if(mobile_sensor_total_time == 0)
				next
			detected_node_impact_score = detected_node_impact_score / mobile_sensor_total_time
			final_mobile_utility_score = final_mobile_utility_score + detected_node_impact_score
			# print("HERE")
			# print(detected_node_impact_score)
			# print(final_mobile_utility_score)
		}
		final_mobile_utility_score = as.numeric(final_mobile_utility_score / (mobile_sensor_cost * number_of_mobile_sensors))
		# final_mobile_utility_score = as.numeric(final_mobile_utility_score)
	}
	if(length(final_static_utility_score)>1)
		final_static_utility_score = final_static_utility_score[1]
	if(length(final_mobile_utility_score)>1)
		final_mobile_utility_score = final_mobile_utility_score[1]
	# print("FINAL SCORE")
	# print(final_static_utility_score)
	# print(final_mobile_utility_score)
	if(final_static_utility_score == -1 && final_mobile_utility_score == -1)
	{
		final_utility_score = -100
		final_node_result = 1
		final_node_number = 0
	}
	else if(final_mobile_utility_score >= final_static_utility_score)
	{
		# print("HERE")
		final_utility_score = final_mobile_utility_score
		final_node_result = 0
		final_node_number = number_of_mobile_sensors
	}
	else
	{	
		# print("OMG")
		# cat(final_static_utility_score,' ',final_mobile_utility_score,'\n')
		final_utility_score = final_static_utility_score
		final_node_result = 1
		final_node_number = number_of_mobile_sensors
	}
	# print("RETURN VECTOR")
	return_vector = c(as.numeric(final_utility_score),as.numeric(final_node_result),as.numeric(final_node_number))
	# print(return_vector)
	return(return_vector)
}



########################################################################################## 
## Beginning of sensor placement algorithm

isCovered_list = rep(FALSE,length(unique_node_id))
isPlaced_list = rep(FALSE,length(unique_node_id))
static_sensor_placed = c()
mobile_sensor_placed = c()
mobile_number_deployed = c()

mobile_sensor_deployment_set = c()
node_shortest_detection_time_set = rep(Inf,length(unique_node_id))

uncovered_indices = which(isCovered_list == FALSE)

sensor_order = unique_node_id # Setting initial order to be the original node order

BUDGET = 10000000
static_sensor_cost = 6
mobile_sensor_cost = 1

counter = 0
old_utility_score = c()

while(BUDGET > 0 && length(uncovered_indices)>0)
# for(p in 1:2)
{
	utility_score = c()
	F_utility_score = c()
	utility_score = c()
	node_result_store = c()
	node_number_store = c()
	# second_score_store = c()
	# third_score_store = c()
	# total_score_store = c()
	unique_detection_store = c()
	print("Uncovered length")
	print(length(uncovered_indices))
	print("MOBILE DEPL SET")
	print(length(mobile_sensor_deployment_set))


	result_flag = c()
	deployed_number = c()
	
	for(i in 1:length(sensor_order))
	{
		# print("I VALUE")
		# print(i)
		# utility_vector = computeUtility(unique_node_id,sensor_order[i],detectionCapability,detectionTime,traversalCapability,traversalTime,
		# 	impactMatrix,static_sensor_cost,mobile_sensor_cost,triangle_score,mobile_sensor_deployment_set,node_shortest_detection_time_set,
		# 	static_sensor_placed,mobile_sensor_placed)

		# current_node_utility = utility_vector[1] # Utility of placing sensor at current node
		# current_node_result = utility_vector[2]	# Type of sensor placed to get that utility - mobile or static (0,1)
		# current_node_number = utility_vector[3] # If mobile, number of sensors to be placed

		current_index = which(unique_node_id==sensor_order[i])

		nodes_detected_by_current_sensor = detectionCapability[current_index,]
		nodes_detected_by_current_sensor = which(nodes_detected_by_current_sensor == 1)

		nodes_traversed_by_current_sensor = traversalCapability[current_index,]
		nodes_traversed_by_current_sensor = which(nodes_traversed_by_current_sensor == 1)

		static_score = length(which(isCovered_list[nodes_detected_by_current_sensor] == FALSE))
		mobile_score = length(which(isCovered_list[nodes_traversed_by_current_sensor] == FALSE))

		if(mobile_score >= static_score)
		{
			unique_detection_score = mobile_score
			current_node_result = 0
			current_node_number = numberOfMobileSensors(unique_node_id,sensor_order[i],traversalCapability)
		}

		if(static_score > mobile_score)
		{
			unique_detection_score = static_score
			current_node_result = 1
			current_node_number = numberOfMobileSensors(unique_node_id,sensor_order[i],traversalCapability)
		}

		# unique_detection_score = length(which(isCovered_list[nodes_detected_by_current_sensor] == FALSE))
		# print("SCORES")
		# print(utility_vector)
		# print(unique_detection_score)
		# print(current_node_utility)
		# print(current_node_result)
		# node_utility_score = as.numeric(unique_detection_score) + as.numeric(current_node_utility)
		node_utility_score = as.numeric(unique_detection_score)
		if(unique_detection_score == 0)
			node_utility_score = -100
		unique_detection_store = c(unique_detection_store,unique_detection_score)
		
		F_utility_score = c(F_utility_score,node_utility_score)
		# F_utility_score = c(F_utility_score,unique_detection_score)

		if(counter == 1 && i > 1)
		{
			if(node_utility_score < F_utility_score[i-1])
			{
				utility_score = c(utility_score,rep(0,(length(sensor_order) - i + 1)))
				node_result_store = c(node_result_store,rep(0,(length(sensor_order) - i + 1 )))
				node_number_store = c(node_number_store,rep(0,(length(sensor_order) - i + 1 )))
				break
			}
		}
		
		utility_score = c(utility_score,node_utility_score)
		node_result_store = c(node_result_store,current_node_result)
		node_number_store = c(node_number_store,current_node_number)
	}
	# print("MOBILE DEPLOYMEnt SEt")
	# print(length(mobile_sensor_deployment_set))

	index_to_place_sensor = which(utility_score == max(utility_score))
	if(length(index_to_place_sensor)>1)
		index_to_place_sensor = index_to_place_sensor[1]
	utility_of_sensor_to_be_placed = utility_score[index_to_place_sensor]
	node_result_of_sensor_to_be_placed = node_result_store[index_to_place_sensor]
	node_number_of_sensor_to_be_placed = node_number_store[index_to_place_sensor]
	print("MAX UTILITY SCORE")
	print(max(utility_score))
	# print(node_result_of_sensor_to_be_placed)
	current_node_index = which(unique_node_id == sensor_order[index_to_place_sensor])
	nodes_detected_by_max_utility = which(detectionCapability[current_node_index,]==1)
	temp_vector = c()
	for(i in 1:length(mobile_sensor_deployment_set))
	{
		temp_index = which(sensor_order == mobile_sensor_deployment_set[i])
		temp_vector = c(temp_vector,utility_score[temp_index])
	}
	# print("MOBILE SCORE ")
	# print(temp_vector)

	if(length(which(temp_vector==max(utility_score)))>0)
		node_result_of_sensor_to_be_placed = 0

	if(node_result_of_sensor_to_be_placed == 1) # Max utility belongs to static sensor
	{
		static_sensor_placed = c(static_sensor_placed,as.character(sensor_order[index_to_place_sensor])) # We use sensor order as it keeps changing for submodularity
		BUDGET = BUDGET - static_sensor_cost

		current_node_index = which(unique_node_id == sensor_order[index_to_place_sensor])
		nodes_detected_by_max_utility = which(detectionCapability[current_node_index,]==1)
		isCovered_list[nodes_detected_by_max_utility] = TRUE
		isCovered_list[current_node_index] = TRUE
		detection_times_of_max_utility = detectionTime[current_node_index]

		for(j in 1:length(nodes_detected_by_max_utility))
		{
			node_shortest_detection_time_set[nodes_detected_by_max_utility[j]] = min(node_shortest_detection_time_set[nodes_detected_by_max_utility[j]],
				detection_times_of_max_utility[nodes_detected_by_max_utility[j]])
		}

		for(j in 1:length(nodes_detected_by_max_utility)) # unlocking the mobile nodes that can be traversed from current location
		{
			traversal_column = traversalCapability[,nodes_detected_by_max_utility[j]]
			required_mobile_rows = which(traversal_column > 0)
			for(k in 1:length(required_mobile_rows))
				mobile_sensor_deployment_set = c(mobile_sensor_deployment_set,as.character(unique_node_id[required_mobile_rows[k]]))
			mobile_sensor_deployment_set = unique(mobile_sensor_deployment_set)
		}
		# cat("Placed static at ",current_node_index,"\n")
	}

	if(node_result_of_sensor_to_be_placed == 0) # Max utility belongs to mobile sensor
	{
		mobile_sensor_placed = c(mobile_sensor_placed,as.character(sensor_order[index_to_place_sensor]))
		mobile_number_deployed = c(mobile_number_deployed,node_number_of_sensor_to_be_placed)
		BUDGET = BUDGET - (node_number_of_sensor_to_be_placed * mobile_sensor_cost)

		current_node_index = which(unique_node_id == sensor_order[index_to_place_sensor])
		# nodes_detected_by_max_utility = which(traversalCapability[current_node_index,]==1)
		nodes_detected_by_max_utility = which(detectionCapability[current_node_index,]==1)
		isCovered_list[nodes_detected_by_max_utility] = TRUE
		isCovered_list[current_node_index] = TRUE
		# cat("Placed mobile at ",current_node_index,"\n")
	}
	uncovered_indices = which(isCovered_list == FALSE)

	# sorting_df = as.data.frame(cbind(utility_score,sensor_order,unique_detection_store))
	# colnames(sorting_df) = NULL
	# sorting_df[,1] = as.numeric(as.character(sorting_df[,1]))
	# sorting_df[,2] = as.character(sorting_df[,2])
	# # sorting_df = sorting_df[-index_to_place_sensor,]
	# if(max(unique_detection_store)>10)
	# {
	# 	sorting_df = sorting_df[order(-sorting_df[,1]),]
	# 	sorting_df = sorting_df[-1,]
	# }
	# if(max(unique_detection_store)<=10)
	# {
	# 	# print(unique_detection_store)
	# 	sorting_df = sorting_df[-index_to_place_sensor,]
	# 	sorting_df = sorting_df[order(-sorting_df[,3])]
	# }
	# sensor_order = as.vector(sorting_df[,2])
	# if(counter == 0)
	# 	counter = 1	
	sorting_df = as.data.frame(cbind(utility_score,sensor_order))
	colnames(sorting_df) = NULL
	sorting_df[,1] = as.numeric(as.character(sorting_df[,1]))
	sorting_df[,2] = as.character(sorting_df[,2])
	# sorting_df = sorting_df[-index_to_place_sensor,]
	sorting_df = sorting_df[order(-sorting_df[,1]),]
	# print(sorting_df)
	sorting_df = sorting_df[-1,]
	sensor_order = as.vector(sorting_df[,2])
	# print("FINAL SENSOR ORDER")
	# print(sensor_order)
	if(counter == 0)
		counter = 1	
}

print(static_sensor_placed)
print(mobile_sensor_placed)

print(length(static_sensor_placed))

print(length(mobile_sensor_placed))
print(mobile_number_deployed)


write.table(static_sensor_placed, file = "./sensorLocations/hybrid_coverage_driven_static_locations.csv",row.names=FALSE, col.names=FALSE, sep=",")
write.table(mobile_sensor_placed, file = "./sensorLocations/hybrid_coverage_driven_mobile_locations.csv",row.names=FALSE, col.names=FALSE, sep=",")
write.table(mobile_number_deployed, file = "./sensorLocations/hybrid_coverage_driven_mobile_deployed.csv",row.names=FALSE, col.names=FALSE, sep=",")
print(length(which(isCovered_list==FALSE)))