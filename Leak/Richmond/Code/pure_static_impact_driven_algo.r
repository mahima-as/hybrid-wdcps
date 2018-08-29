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
unique_node_id = node_list
detectionCapability = read.csv("../Output/detectionCapability1.csv",header=FALSE)
# detection_weight_number = c()
# for(i in 1:length(detectionCapability[,1]))
# {
# 	detection_weight_number = c(detection_weight_number,length(which(detectionCapability[i,]==1)))
# }
detectionTime = read.csv("../Output/detectionTime.csv",header=FALSE)
impactMatrix = as.matrix(read.csv("../Output/final_impact_matrix.csv"))
triangle_score = as.vector(as.matrix(read.csv("../Output/final_triangle_score.csv")))
triangle_score = (triangle_score - min(triangle_score)) / (max(triangle_score) - min(triangle_score))

impactMatrix = impactMatrix[,-1]
colnames(impactMatrix) = NULL
rownames(impactMatrix) = NULL
class(impactMatrix) = "numeric"
impactMatrix = (impactMatrix - min(impactMatrix)) / (max(impactMatrix) - min(impactMatrix))


################################################################################################################
# Begin sensor placement algo

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


isCovered_list = rep(FALSE,length(unique_node_id))
isPlaced_list = rep(FALSE,length(unique_node_id))
sensor_placed = c()
uncovered_indices = which(isCovered_list == FALSE)
node_shortest_detection_time_list = rep(Inf,length(unique_node_id))

sensor_order = unique_node_id # Setting initial order to be the original node order


counter = 0
old_utility_score = c()

shortest_detection_time = rep(Inf,length(unique_node_id))

start.time <- Sys.time()

while(length(uncovered_indices) > 0)
# for(q in 1:1)
{
	utility_score = c()
	F_utility_score = c()
	first_score_store = c()
	second_score_store = c()
	third_score_store = c()
	total_score_store = c()
	unique_detection_store = c()
	print(length(uncovered_indices))


	# for(p in 1:length(sensor_order))
	# {
	# 	current_index = which(unique_node_id==sensor_order[p])
	# 	current_detection = which(detectionCapability[current_index,]==1)
	# 	unique_detection_score = length(which(isCovered_list[current_detection]==FALSE))
	# 	unique_detection_store = c(unique_detection_store,unique_detection_score)
	# }
	# unique_detection_store = (unique_detection_store - min(unique_detection_store)) / (max(unique_detection_store) - min(unique_detection_store))

	for(i in 1:length(sensor_order))
	# for(t in 1:1)
	{
		current_index = which(unique_node_id==sensor_order[i])
		# if(isPlaced_list[current_index] == TRUE)
		# {
		# 	utility_score = c(utility_score,-1)
		# 	F_utility_score = c(F_utility_score,-1)
		# 	next
		# }
		first_score = computeTriangleImpactProduct(impactMatrix,triangle_score,current_index)
		
		nodes_detected_by_current = which(detectionCapability[current_index,] == 1)
		detection_times_of_current = detectionTime[current_index,nodes_detected_by_current]

		shortest_detection_times_of_detected_by_current = shortest_detection_time[nodes_detected_by_current]
		required_indices = which(detection_times_of_current < shortest_detection_times_of_detected_by_current)
		nodes_detected_by_current = nodes_detected_by_current[required_indices]
		detection_times_of_current = detection_times_of_current[required_indices]

		second_score = 0
		if(length(nodes_detected_by_current)>0)
		{
		for(j in 1:length(nodes_detected_by_current))
		{
			temp_node = nodes_detected_by_current[j]
			temp_score = computeTriangleImpactProduct(impactMatrix,triangle_score,temp_node)
			# print(temp_score)
			# print(detection_times_of_current[j])
			second_score = as.numeric(second_score + as.numeric(temp_score * detection_times_of_current[j]))
		}
		}
		current_detection = which(detectionCapability[current_index,]==1)
		unique_detection_score = length(which(isCovered_list[current_detection]==FALSE))
		unique_detection_store = c(unique_detection_store,unique_detection_score)
		
		# detection_capability_score = as.numeric(unique_detection_score * (length(which(isCovered_list==FALSE)) - unique_detection_score))
		# detection_capability_score = (detection_weight_number[current_index] - min(detection_weight_number)) / (max(detection_weight_number) - min(detection_weight_number))
		# unique_detection_score = unique_detection_store[i]
		detection_capability_score = unique_detection_score
		# detection_capability_score = unique_detection_store[i]

		total_score = as.numeric(detection_capability_score + first_score + second_score)
		# print(total_score)
		first_score_store = c(first_score_store,first_score)
		second_score_store = c(second_score_store,second_score)
		third_score_store = c(third_score_store,detection_capability_score)
		total_score_store = c(total_score_store,total_score)
		F_utility_score = c(F_utility_score, unique_detection_score)
		
		if(counter ==1 && i > 1)
		{
			if(unique_detection_score < F_utility_score[i-1])
			{
				for(j in i:length(sensor_order))
				{
					# if(isPlaced_list[j] == FALSE)
						utility_score = c(utility_score,0)
				}
				break
			}
		}

		utility_score = c(utility_score,as.numeric(total_score))
	}
	# print("unique detection score")
	# print(unique_detection_store)
	if(max(unique_detection_store)>2)
	{	
		print(">1")
		index_to_place_sensor = which(utility_score == max(utility_score))
	}
	if(max(unique_detection_store)<=2)
	{
		print("==1")
		index_to_place_sensor = which(unique_detection_store == max(unique_detection_store))
	}
	
	if(length(index_to_place_sensor) > 1)
		index_to_place_sensor = index_to_place_sensor[1]
	# print(utility_score)
	# print(index_to_place_sensor)
	sensor_placed = c(sensor_placed,as.character(sensor_order[index_to_place_sensor]))
	current_index = which(unique_node_id == sensor_order[index_to_place_sensor])
	nodes_detected_by_placed_sensor = which(detectionCapability[current_index,]==1)
	isCovered_list[nodes_detected_by_placed_sensor] = TRUE
	isCovered_list[current_index] = TRUE
	isPlaced_list[current_index] = TRUE
	uncovered_indices = which(isCovered_list == FALSE)

	sorting_df = as.data.frame(cbind(utility_score,sensor_order,unique_detection_store))
	colnames(sorting_df) = NULL
	sorting_df[,1] = as.numeric(as.character(sorting_df[,1]))
	sorting_df[,2] = as.character(sorting_df[,2])
	# print(sorting_df[,1])
	if(max(unique_detection_store)>1)
	{
	sorting_df = sorting_df[order(-sorting_df[,1]),]
	# print(sorting_df)
	sorting_df = sorting_df[-1,]
	}
	if(max(unique_detection_store)<=1)
	{
		# print(unique_detection_store)
		sorting_df = sorting_df[-index_to_place_sensor,]
		sorting_df = sorting_df[order(-sorting_df[,3])]
	}
	# print(sorting_df)
	sensor_order = as.vector(sorting_df[,2])
	# print(sensor_order)
	# old_utility_score = as.vector(sorting_df[,1])
	# F_utility_score = as.vector(sorting_df[,2])
	# sensor_order = sensor_order[-index_to_place_sensor]
	if(counter == 0)
		counter = 1
	print("sensor placed length")
	print(length(sensor_placed))

}
# random = as.matrix(cbind(first_score_store,second_score_store,third_score_store,total_score_store))
# print(random)
sensor_placed = sort(sensor_placed)
print(sensor_placed)
print(length(sensor_placed))
print(length(unique(sensor_placed)))

end.time <- Sys.time()
time.taken <- end.time - start.time
print(time.taken)

write.table(sensor_placed, file = "./sensorLocations/pure_static_impact_driven.csv",row.names=FALSE, col.names=FALSE, sep=",")
print("finished")