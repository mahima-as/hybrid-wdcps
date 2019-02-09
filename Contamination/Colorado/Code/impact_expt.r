hybrid_impact_static_locations = as.vector(as.matrix(read.csv("./sensorLocations/static_sensor_locations.csv")))
hybrid_impact_mobile_locations = as.vector(as.matrix(read.csv("./sensorLocations/mobile_sensor_locations.csv")))
hybrid_coverage_static_locations = as.vector(as.matrix(read.csv("./sensorLocations/hybrid_coverage_driven_static_locations.csv")))
hybrid_coverage_mobile_locations = as.vector(as.matrix(read.csv("./sensorLocations/hybrid_coverage_driven_mobile_locations.csv")))

pure_static_coverage_locations = as.vector(as.matrix(read.csv("./sensorLocations/pure_static_coverage_driven.csv")))
pure_static_impact_locations = as.vector(as.matrix(read.csv("./sensorLocations/pure_static_impact_driven.csv")))

read_input = readLines("../Data/final_input.inp")
read_input = gsub("\\s+"," ",read_input)
read_input = gsub("\t|^\\s+|\\s+$","",read_input)

junction_beginning = (which(read_input == "[JUNCTIONS]")) + 1
junction_ending = which(read_input == "[RESERVOIRS]") - 2
junction_list = read_input[junction_beginning:junction_ending]
node_list = c()

for(i in 1:length(junction_list))
{
	split_line = strsplit(junction_list[i]," ")[[1]]
	node_list = c(node_list,split_line[1])
}
unique_node_id = node_list # Getting Unique node ID list 

################## Reading the other matrices ##########################################

detectionCapability = read.csv("../Output/detectionCapability1.csv",header=FALSE)

detectionTime = read.csv("../Output/detectionTime1.csv",header=FALSE)
traversalCapability = read.csv("../Output/traversalCapability1.csv",header=FALSE)

traversalTime = read.csv("../Output/traversalTime1.csv",header=FALSE)
population_values = as.data.frame(read.csv("../Output/population_values.csv",header=FALSE))
population_values = population_values$V1


node_input_df = as.data.frame(read.csv("../Output/node_input_df.csv",header=TRUE))
rownames(node_input_df) = NULL
colnames(node_input_df) = NULL
node_input_df = node_input_df[,-1]


########################################################################################## 


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


########################################################################################## 
indices = which(!(is.na(node_input_df[,3])))
minval = min(node_input_df[indices,3])
maxval = max(node_input_df[indices,3])

indices = which((is.na(node_input_df[,3])))
for(i in 1:length(indices))
	node_input_df[indices[i],3] = runif(1,minval,maxval)
pure_static_coverage_locations = which(pure_static_coverage_locations == 1)
pure_static_impact_locations = match(pure_static_impact_locations,unique_node_id)
hybrid_coverage_static_locations = match(hybrid_coverage_static_locations,unique_node_id)
hybrid_coverage_mobile_locations = match(hybrid_coverage_mobile_locations,unique_node_id)
hybrid_impact_static_locations = match(hybrid_impact_static_locations,unique_node_id)
hybrid_impact_mobile_locations = match(hybrid_impact_mobile_locations,unique_node_id)

print(length(pure_static_coverage_locations))
print(length(pure_static_impact_locations))
print(length(hybrid_coverage_static_locations))
print(length(hybrid_coverage_mobile_locations))
print(length(hybrid_impact_static_locations))
print(length(hybrid_impact_mobile_locations))



init_perc = 0.05

final_pure_static_coverage_score_leak = c()
final_pure_static_coverage_time_leak = c()

final_pure_static_impact_score_leak = c()
final_pure_static_impact_time_leak = c()

final_hybrid_coverage_score_leak = c()
final_hybrid_coverage_time_leak = c()

final_hybrid_impact_score_leak = c()
final_hybrid_impact_time_leak = c()

iteration_number = 15

final_pure_static_coverage_cost = c()
final_pure_static_impact_cost = c()
final_hybrid_coverage_cost = c()
final_hybrid_impact_cost = c()

final_pure_static_coverage_eff = c()
final_pure_static_impact_eff = c()
final_hybrid_coverage_eff = c()
final_hybrid_impact_eff = c()

for(i in 1:10)
{

	print(i)
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

	init_perc = init_perc + 0.05

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

			pure_static_coverage_times = min(detectionTime[pure_static_coverage_locations,current_leak])
			pure_static_impact_times = min(detectionTime[pure_static_impact_locations,current_leak])

			hybrid_coverage_static_times = min(detectionTime[hybrid_coverage_static_locations,current_leak])
			hybrid_coverage_mobile_times = min(traversalTime[hybrid_coverage_mobile_locations,current_leak])
			hybrid_coverage_times = min(hybrid_coverage_static_times,hybrid_coverage_mobile_times)


			hybrid_impact_static_times = min(detectionTime[hybrid_impact_static_locations,current_leak])
			hybrid_impact_mobile_times = min(traversalTime[hybrid_impact_mobile_locations,current_leak])
			hybrid_impact_times = min(hybrid_impact_static_times,hybrid_impact_mobile_times)
		

			impact_score_current_leak = as.numeric(computeTriangleImpactProduct(population_values,node_input_df,current_leak))

			temp_pure_static_coverage_time_leak[k] = temp_pure_static_coverage_time_leak[k] + min(pure_static_coverage_times)
			temp_pure_static_impact_time_leak[k] = temp_pure_static_impact_time_leak[k] + min(pure_static_impact_times)
			temp_hybrid_coverage_time_leak[k] = temp_hybrid_coverage_time_leak[k] + min(hybrid_coverage_times)
			temp_hybrid_impact_time_leak[k] = temp_hybrid_impact_time_leak[k] + min(hybrid_impact_times)

			temp_pure_static_coverage_score_leak[k] = temp_pure_static_coverage_score_leak[k] +  (impact_score_current_leak * min(pure_static_coverage_times))
			temp_pure_static_impact_score_leak[k] = temp_pure_static_impact_score_leak[k] + (impact_score_current_leak * min(pure_static_impact_times))
			temp_hybrid_coverage_score_leak[k] = temp_hybrid_coverage_score_leak[k] + (impact_score_current_leak * min(hybrid_coverage_times))
			temp_hybrid_impact_score_leak[k] = temp_hybrid_impact_score_leak[k] + (impact_score_current_leak * min(hybrid_impact_times))

		}

	}

	temp_pure_static_coverage_time_leak = temp_pure_static_coverage_time_leak / iteration_number
	temp_pure_static_impact_time_leak = temp_pure_static_impact_time_leak / iteration_number
	temp_hybrid_coverage_time_leak = temp_hybrid_coverage_time_leak / iteration_number
	temp_hybrid_impact_time_leak = temp_hybrid_impact_time_leak / iteration_number

	temp_pure_static_coverage_score_leak = temp_pure_static_coverage_score_leak / iteration_number
	temp_pure_static_impact_score_leak  = temp_pure_static_impact_score_leak / iteration_number
	temp_hybrid_coverage_score_leak = temp_hybrid_coverage_score_leak / iteration_number
	temp_hybrid_impact_score_leak = temp_hybrid_impact_score_leak / iteration_number

	final_pure_static_coverage_score_leak = c(final_pure_static_coverage_score_leak, mean(temp_pure_static_coverage_score_leak))
	final_pure_static_impact_score_leak = c(final_pure_static_impact_score_leak, mean(temp_pure_static_impact_score_leak))
	final_hybrid_coverage_score_leak = c(final_hybrid_coverage_score_leak, mean(temp_hybrid_coverage_score_leak))
	final_hybrid_impact_score_leak = c(final_hybrid_impact_score_leak,mean(temp_hybrid_impact_score_leak))


	final_pure_static_coverage_time_leak = c(final_pure_static_coverage_time_leak, mean(temp_pure_static_coverage_time_leak))
	final_pure_static_impact_time_leak = c(final_pure_static_impact_time_leak, mean(temp_pure_static_impact_time_leak))
	final_hybrid_coverage_time_leak = c(final_hybrid_coverage_time_leak, mean(temp_hybrid_coverage_time_leak))
	final_hybrid_impact_time_leak = c(final_hybrid_impact_time_leak,mean(temp_hybrid_impact_time_leak))

	final_pure_static_coverage_cost = c(final_pure_static_coverage_cost,sum(temp_pure_static_coverage_score_leak) * (5 * length(pure_static_coverage_locations)))
	final_pure_static_impact_cost = c(final_pure_static_impact_cost,sum(temp_pure_static_impact_score_leak) * (5 * length(pure_static_impact_locations)))
	final_hybrid_coverage_cost = c(final_hybrid_coverage_cost,sum(temp_hybrid_coverage_score_leak) * ((5 * length(hybrid_coverage_static_locations)) + length(hybrid_coverage_mobile_locations)))
	final_hybrid_impact_cost = c(final_hybrid_impact_cost,sum(temp_hybrid_impact_score_leak) * ((5 * length(hybrid_impact_static_locations)) + length(hybrid_impact_mobile_locations)))


	final_pure_static_coverage_eff = c(final_pure_static_coverage_eff,sum(temp_pure_static_coverage_score_leak) / (5 * length(pure_static_coverage_locations)))
	final_pure_static_impact_eff = c(final_pure_static_impact_eff,sum(temp_pure_static_impact_score_leak) / (5 * length(pure_static_impact_locations)))
	final_hybrid_coverage_eff = c(final_hybrid_coverage_eff,sum(temp_hybrid_coverage_score_leak) / ((5 * length(hybrid_coverage_static_locations)) + length(hybrid_coverage_mobile_locations)))
	final_hybrid_impact_eff = c(final_hybrid_impact_eff,sum(temp_hybrid_impact_score_leak) / ((5 * length(hybrid_impact_static_locations)) + length(hybrid_impact_mobile_locations)))



}


swap <- function(a,b)
{
	t = a
	a = b
	b = t
	return(list(a,b))
}

normalize <- function(vect,max_val,min_val)
{
	vect = (vect - min_val) / (max_val - min_val)
	return(vect)
}

temp = c(final_pure_static_coverage_score_leak,final_pure_static_impact_score_leak,final_hybrid_coverage_score_leak,final_hybrid_impact_score_leak)
minval = min(temp)
maxval = max(temp)

final_pure_static_coverage_score_leak = normalize(final_pure_static_coverage_score_leak,maxval,minval)
final_pure_static_impact_score_leak = normalize(final_pure_static_impact_score_leak,maxval,minval)
final_hybrid_coverage_score_leak = normalize(final_hybrid_coverage_score_leak,maxval,minval)
final_hybrid_impact_score_leak = normalize(final_hybrid_impact_score_leak,maxval,minval)

temp = c(final_pure_static_coverage_cost,final_pure_static_impact_cost,final_hybrid_coverage_cost,final_hybrid_impact_cost)
minval = min(temp)
maxval = max(temp)

final_pure_static_coverage_cost = normalize(final_pure_static_coverage_cost,maxval,minval)
final_pure_static_impact_cost = normalize(final_pure_static_impact_cost,maxval,minval)
final_hybrid_coverage_cost = normalize(final_hybrid_coverage_cost,maxval,minval)
final_hybrid_impact_cost = normalize(final_hybrid_impact_cost,maxval,minval)

temp = c(final_pure_static_coverage_eff,final_pure_static_impact_eff,final_hybrid_coverage_eff,final_hybrid_impact_eff)
minval = min(temp)
maxval = max(temp)

final_pure_static_coverage_eff = normalize(final_pure_static_coverage_eff,maxval,minval)
final_pure_static_impact_eff = normalize(final_pure_static_impact_eff,maxval,minval)
final_hybrid_coverage_eff = normalize(final_hybrid_coverage_eff,maxval,minval)
final_hybrid_impact_eff = normalize(final_hybrid_impact_eff,maxval,minval)


final_df = data.frame(final_pure_static_coverage_time_leak,final_pure_static_impact_time_leak,final_hybrid_coverage_time_leak,final_hybrid_impact_time_leak,
	final_pure_static_coverage_score_leak,final_pure_static_impact_score_leak,final_hybrid_impact_score_leak,final_hybrid_coverage_score_leak,
	final_hybrid_coverage_cost,final_hybrid_impact_cost,final_pure_static_coverage_cost,final_pure_static_impact_cost,
	final_hybrid_coverage_eff,final_pure_static_impact_eff,final_hybrid_impact_eff,final_pure_static_coverage_eff)


colnames(final_df) = c("staticImpactTime","hybridImpactTime","staticCoverageTime","hybridCoverageTime","staticImpactScore","hybridImpactScore"
	,"staticCoverageScore","hybridCoverageScore","staticImpactCost","hybridImpactCost","staticCoverageCost","hybridCoverageCost",
	"staticImpactEff","hybridImpactEff","staticCoverageEff","hybridCoverageEff")
write.csv(final_df,file="geocorrelated.csv",row.names=FALSE)
