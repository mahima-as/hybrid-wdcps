read_input = readLines("../../Data/final_input.inp")
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

detectionCapability = read.csv("../../Output/detectionCapability1.csv",header=FALSE)

detectionTime = read.csv("../../Output/detectionTime.csv",header=FALSE)
traversalCapability = read.csv("../../Output/traversalCapability1.csv",header=FALSE)

traversalTime = read.csv("../../Output/traversalTime.csv",header=FALSE)
population_values = as.data.frame(read.csv("../../Output/population_values.csv",header=FALSE))
population_values = population_values$V1


node_input_df = as.data.frame(read.csv("../../Output/node_input_df.csv",header=TRUE))
rownames(node_input_df) = NULL
colnames(node_input_df) = NULL
node_input_df = node_input_df[,-1]


########################################################################################## 

# Normalizing the matrices - triangle score, impact matrix, detection time and traversal time  


detectionTimeArray = as.matrix(detectionTime)
class(detectionTimeArray) = "numeric"
detectionTimeArray = as.vector(detectionTimeArray)
detectionTimeArray = detectionTimeArray[which(is.finite(detectionTimeArray) & detectionTimeArray != 0)]
# print(detectionTimeArray)
# print(length(which(detectionTimeArray<0)))
detectionTime = as.matrix(detectionTime)
class(detectionTime) = "numeric"
# for(i in 1:length(detectionTime[,1]))
# {
# 	current_row = detectionTime[i,]
# 	indices = which(is.finite(current_row) & current_row!=0)
# 	for(j in 1:length(indices))
# 	{
# 		current_row[indices[j]] = (current_row[indices[j]] - min(detectionTimeArray)) / (max(detectionTimeArray) - min(detectionTimeArray))
# 	}
# 	detectionTime[i,] = current_row
# }

traversalTimeArray = as.matrix(traversalTime)
class(traversalTimeArray) = "numeric"
traversalTimeArray = as.vector(traversalTimeArray)
traversalTimeArray = traversalTimeArray[which(is.finite(traversalTimeArray) & traversalTimeArray != 0)]
traversalTime = as.matrix(traversalTime)
class(traversalTime) = "numeric"
# for(i in 1:length(traversalTime[,1]))
# {
# 	current_row = traversalTime[i,]
# 	indices = which(is.finite(current_row) & current_row!=0)
# 	for(j in 1:length(indices))
# 	{
# 		current_row[indices[j]] = (current_row[indices[j]] - min(traversalTimeArray)) / (max(traversalTimeArray) - min(traversalTimeArray))
# 	}
# 	traversalTime[i,] = current_row
# }
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
computeTriangleImpactProduct = function(population_values,node_input_df,node_index)
{
	score = 0
	# impacted_indices = which(impactMatrix[node_index,] > 0)
	# if(length(impacted_indices) > 0)
	# {
	# 	for(i in 1:length(impacted_indices))
	# 	{
	# 		index = impacted_indices[i]
	# 		score = as.numeric(score + as.numeric(impactMatrix[node_index,index] * triangle_score[index]))
	# 	}
	# }

	score = score + as.numeric(population_values[node_index]) + as.numeric(node_input_df[node_index,3])
	# print("SCORE")
	# print(score)
	return(score)
}
################################################################################################
# Function to compute the utility of a sensor

computeUtility <- function(unique_node_id,current_sensor_id,detectionCapability,detectionTime,traversalCapability,traversalTime,population_values,
	static_sensor_cost,mobile_sensor_cost,node_input_df,mobile_sensor_deployment_set,node_shortest_detection_time_set,static_sensor_placed,mobile_sensor_placed)
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

	number_of_mobile_sensors = numberOfMobileSensors(unique_node_id,current_sensor_id,traversalCapability)
	mobile_sensor_deployment_set = mobile_sensor_deployment_set[-which(is.na(mobile_sensor_deployment_set))]

	if(!(current_sensor_id %in% static_sensor_placed))
	{
		final_static_utility_score = 0
		# print("HERE")
		# print(length(nodes_detected_by_current_sensor))
		for(i in 1:length(nodes_detected_by_current_sensor))
		{
			detected_node = nodes_detected_by_current_sensor[i]
			# print(detection_times_of_current_sensor[i])
			# print(node_shortest_detection_time_set[i])
			# Only consider the detected node if it is detected faster by current node than existing placed nodes
			if(is.finite(node_shortest_detection_time_set[i]))
			{
				if(detection_times_of_current_sensor[i] >= node_shortest_detection_time_set[i])
					next
			}
			# else
			# 	next
			detected_node_impact_score = as.numeric(computeTriangleImpactProduct(population_values,node_input_df,detected_node))
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
			detected_node_impact_score = as.numeric(computeTriangleImpactProduct(population_values,node_input_df,detected_node))
			mobile_sensor_total_time = traversal_times_of_current_sensor[i] + node_shortest_detection_time_set[i]
			# mobile_sensor_total_time = traversal_times_of_current_sensor[i]
			if(mobile_sensor_total_time == 0)
				next
			detected_node_impact_score = detected_node_impact_score / mobile_sensor_total_time
			final_mobile_utility_score = final_mobile_utility_score + detected_node_impact_score
		}
		final_mobile_utility_score = as.numeric(final_mobile_utility_score / (mobile_sensor_cost * number_of_mobile_sensors))
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
		final_utility_score = final_mobile_utility_score
		final_node_result = 0
		final_node_number = number_of_mobile_sensors
	}
	else
	{
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
minval = min(node_input_df[,3])
maxval = max(node_input_df[,3])
indices = which(node_input_df[,3]==0)
for(i in 1:length(indices))
	node_input_df[indices[i],3] = runif(1,minval,maxval)
cost_ratio_addition = 0
cost_ratio_expt_impact = c()

for(p in 1:10)
{
	print("Current iteration")
	print(p)
	isCovered_list = rep(FALSE,length(unique_node_id))
	isPlaced_list = rep(FALSE,length(unique_node_id))
	static_sensor_placed = c()
	mobile_sensor_placed = c()
	mobile_number_deployed = c()

	mobile_sensor_deployment_set = c()
	node_shortest_detection_time_set = rep(Inf,length(unique_node_id))

	uncovered_indices = which(isCovered_list == FALSE)

	sensor_order = unique_node_id # Setting initial order to be the original node order

	BUDGET = 100000
	mobile_sensor_cost = 1
	static_sensor_cost = cost_ratio_addition + mobile_sensor_cost

	cost_ratio_addition = cost_ratio_addition + 1

	counter = 0
	old_utility_score = c()

	budget_expt_sensor_order = c()
	budget_expt_sensor_number = c()
	budget_expt_unique_covered = c()

	while(BUDGET > 0 && length(uncovered_indices)>0)
	# for(p in 1:1)
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


		result_flag = c()
		deployed_number = c()

		for(i in 1:length(sensor_order))
		# for(i in 1:1)
		{
			utility_vector = computeUtility(unique_node_id,sensor_order[i],detectionCapability,detectionTime,traversalCapability,traversalTime,
				population_values,static_sensor_cost,mobile_sensor_cost,node_input_df,mobile_sensor_deployment_set,node_shortest_detection_time_set,
				static_sensor_placed,mobile_sensor_placed)

			current_node_utility = utility_vector[1] # Utility of placing sensor at current node
			current_node_result = utility_vector[2]	# Type of sensor placed to get that utility - mobile or static (0,1)
			current_node_number = utility_vector[3] # If mobile, number of sensors to be placed

			current_index = which(unique_node_id==sensor_order[i])

			nodes_detected_by_current_sensor = detectionCapability[current_index,]
			nodes_detected_by_current_sensor = which(nodes_detected_by_current_sensor == 1)

			unique_detection_score = length(which(isCovered_list[nodes_detected_by_current_sensor] == FALSE))
			# print("SCORES")
			# print(utility_vector)
			# print(unique_detection_score)
			# print(current_node_utility)
			# print(current_node_result)
			# node_utility_score = as.numeric(unique_detection_score) + as.numeric(current_node_utility)

			node_utility_score = as.numeric(current_node_utility)

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

		# print(length(which(isCovered_list[nodes_detected_by_max_utility]==FALSE)))
		
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

		budget_expt_sensor_order = c(budget_expt_sensor_order,sensor_order[index_to_place_sensor])
		if(node_result_of_sensor_to_be_placed == 1)
			budget_expt_sensor_number = c(budget_expt_sensor_number,1)
		if(node_result_of_sensor_to_be_placed == 0)
			budget_expt_sensor_number = c(budget_expt_sensor_number,node_number_of_sensor_to_be_placed)

		budget_expt_unique_covered = c(budget_expt_unique_covered,length(which(isCovered_list == TRUE)))

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

	# print(static_sensor_placed)
	# print(mobile_sensor_placed)

	# print(length(static_sensor_placed))

	# print(length(mobile_sensor_placed))
	# print(mobile_number_deployed)


	# budget_expt_df = data.frame(budget_expt_sensor_order,budget_expt_sensor_number,budget_expt_unique_covered)
	# colnames(budget_expt_df) = c("sensorName","sensor#","eventsCovered")
	# write.table(budget_expt_df,file="./budgetExpt/hybrid_impact_results.csv",row.names=FALSE,col.names = FALSE,sep=",")
	# write.table(static_sensor_placed, file = "./sensorLocations/static_sensor_locations.csv",row.names=FALSE, col.names=FALSE, sep=",")
	# write.table(mobile_sensor_placed, file = "./sensorLocations/mobile_sensor_locations.csv",row.names=FALSE, col.names=FALSE, sep=",")
	# write.table(mobile_number_deployed, file = "./sensorLocations/mobile_number_deployed.csv",row.names=FALSE, col.names=FALSE, sep=",")
	# print(length(which(isCovered_list==FALSE)))




	hybrid_impact_static_locations = match(static_sensor_placed,unique_node_id)
	hybrid_impact_mobile_locations = match(mobile_sensor_placed,unique_node_id)

	print(hybrid_impact_static_locations)
	print(hybrid_impact_mobile_locations)

	init_perc = 0.3

	iteration_number = 15

		number_of_events = ceiling(init_perc * length(unique_node_id))

		temp_pure_static_coverage_score_leak = rep(0,number_of_events)
		temp_pure_static_impact_score_leak = rep(0,number_of_events)
		temp_hybrid_coverage_score_leak = rep(0,number_of_events)
		temp_hybrid_impact_score_leak = rep(0,number_of_events)

		temp_pure_static_coverage_time_leak = rep(0,number_of_events)
		temp_pure_static_impact_time_leak = rep(0,number_of_events)
		temp_hybrid_coverage_time_leak = rep(0,number_of_events)
		temp_hybrid_impact_time_leak = rep(0,number_of_events)

		temp_pure_static_coverage_cost = rep(0,number_of_events)
		temp_pure_static_impact_cost = rep(0,number_of_events)
		temp_hybrid_coverage_cost = rep(0,number_of_events)
		temp_hybrid_impact_cost = rep(0,number_of_events)


		number_of_clusters = floor(sqrt(number_of_events))

		for(k in 1:iteration_number)
		{
			leak_locations = sample(1:length(unique_node_id),number_of_clusters,replace=FALSE)

			total_leak_locations = c()

			for(j in 1:length(leak_locations))
			{
				current_leak = leak_locations[j]
				current_set_leak = c(current_leak:(current_leak+number_of_clusters-1))
				if(length(which(current_set_leak>length(unique_node_id)))>0)
					current_set_leak = current_set_leak[-which(current_set_leak>length(unique_node_id))]
				total_leak_locations = c(total_leak_locations,current_set_leak)
			}

			for(j in 1:length(total_leak_locations))
			{
				current_leak = total_leak_locations[j]

				# pure_static_coverage_times = min(detectionTime[pure_static_coverage_locations,current_leak])
				# pure_static_impact_times = min(detectionTime[pure_static_impact_locations,current_leak])

				# hybrid_coverage_static_times = min(detectionTime[hybrid_coverage_static_locations,current_leak])
				# hybrid_coverage_mobile_times = min(traversalTime[hybrid_coverage_mobile_locations,current_leak])
				# hybrid_coverage_times = min(hybrid_coverage_static_times,hybrid_coverage_mobile_times)


				hybrid_impact_static_times = min(detectionTime[hybrid_impact_static_locations,current_leak])
				hybrid_impact_mobile_times = min(traversalTime[hybrid_impact_mobile_locations,current_leak])
				hybrid_impact_times = min(hybrid_impact_static_times,hybrid_impact_mobile_times)
				if(is.infinite(hybrid_impact_times))
					hybrid_impact_times = 0

				impact_score_current_leak = as.numeric(computeTriangleImpactProduct(population_values,node_input_df,current_leak))

				# temp_pure_static_coverage_time_leak[k] = temp_pure_static_coverage_time_leak[k] + min(pure_static_coverage_times)
				# temp_pure_static_impact_time_leak[k] = temp_pure_static_impact_time_leak[k] + min(pure_static_impact_times)
				# temp_hybrid_coverage_time_leak[k] = temp_hybrid_coverage_time_leak[k] + min(hybrid_coverage_times)
				temp_hybrid_impact_time_leak[k] = temp_hybrid_impact_time_leak[k] + min(hybrid_impact_times)

				# temp_pure_static_coverage_score_leak[k] = temp_pure_static_coverage_score_leak[k] +  (impact_score_current_leak * min(pure_static_coverage_times))
				# temp_pure_static_impact_score_leak[k] = temp_pure_static_impact_score_leak[k] + (impact_score_current_leak * min(pure_static_impact_times))
				# temp_hybrid_coverage_score_leak[k] = temp_hybrid_coverage_score_leak[k] + (impact_score_current_leak * min(hybrid_coverage_times))
				temp_hybrid_impact_score_leak[k] = temp_hybrid_impact_score_leak[k] + (impact_score_current_leak * min(hybrid_impact_times))

			}

		}

		# temp_pure_static_coverage_time_leak = temp_pure_static_coverage_time_leak / iteration_number
		# temp_pure_static_impact_time_leak = temp_pure_static_impact_time_leak / iteration_number
		# temp_hybrid_coverage_time_leak = temp_hybrid_coverage_time_leak / iteration_number
		temp_hybrid_impact_time_leak = temp_hybrid_impact_time_leak / iteration_number
		
		# temp_pure_static_coverage_score_leak = temp_pure_static_coverage_score_leak / iteration_number
		# temp_pure_static_impact_score_leak  = temp_pure_static_impact_score_leak / iteration_number
		# temp_hybrid_coverage_score_leak = temp_hybrid_coverage_score_leak / iteration_number
		temp_hybrid_impact_score_leak = temp_hybrid_impact_score_leak / iteration_number
		
		# final_pure_static_coverage_score_leak = c(final_pure_static_coverage_score_leak, mean(temp_pure_static_coverage_score_leak))
		# final_pure_static_impact_score_leak = c(final_pure_static_impact_score_leak, mean(temp_pure_static_impact_score_leak))
		# final_hybrid_coverage_score_leak = c(final_hybrid_coverage_score_leak, mean(temp_hybrid_coverage_score_leak))
		# final_hybrid_impact_score_leak = c(final_hybrid_impact_score_leak,mean(temp_hybrid_impact_score_leak))
		cost_ratio_expt_impact = c(cost_ratio_expt_impact,mean(temp_hybrid_impact_score_leak))
}
print(cost_ratio_expt_impact)
write.table(cost_ratio_expt_impact,file="hybrid_impact_results.csv",row.names=FALSE,col.names=FALSE,sep=",")