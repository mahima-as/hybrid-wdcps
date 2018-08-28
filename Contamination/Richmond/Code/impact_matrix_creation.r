options(scipen=999)
library("ptinpoly")

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


read_triangle_nodes = read.table("./brezo_files/richmond.1.ele")
triangle_nodes = as.matrix(read_triangle_nodes)
colnames(triangle_nodes) = NULL

read_node_coordinates = read.table("./brezo_files/richmond.1.node")
node_coordinates = as.matrix(read_node_coordinates)
node_coordinates = node_coordinates[-1,]
node_coordinates = cbind(node_coordinates[,2],node_coordinates[,3])
colnames(node_coordinates) = NULL

node_coordinates[,1] = node_coordinates[,1] / 10000
node_coordinates[,2] = node_coordinates[,2] / 10000
node_coordinates[,1] = -1 * node_coordinates[,1]

# Above part basically reads the node and triangle details and makes them into matrices
# for easy processing so triangle[node] gives coordinates of the triangle corner point


# Reading triangle population details 

read_population_details = read.csv("./brezo_files/triangle_area_mapping.csv",header=TRUE)
triangle_population = as.matrix(read_population_details)
colnames(triangle_population) = NULL
triangle_population = as.numeric(as.character(triangle_population[,2]))
# triangle_population_normalized = (triangle_population - min(triangle_population)) / (max(triangle_population) - min(triangle_population))

read_coordinate_mapping = read.csv("./brezo_files/epanet_richmond_coordinate_mapping.csv",header=TRUE)
coordinate_mapping = as.data.frame(as.character(read_coordinate_mapping[,1]))
coordinate_mapping = cbind(coordinate_mapping,as.numeric(as.character(read_coordinate_mapping[,4])))
coordinate_mapping = cbind(coordinate_mapping,as.numeric(as.character(read_coordinate_mapping[,5])))
colnames(coordinate_mapping) = NULL
rownames(coordinate_mapping) = NULL
coordinate_mapping[,2] = coordinate_mapping[,2] / 10000
coordinate_mapping[,3] = coordinate_mapping[,3] / 10000
coordinate_mapping[,2] = -1 * coordinate_mapping[,2]

coordinate_matrix = as.matrix(coordinate_mapping[,2])
coordinate_matrix = cbind(coordinate_matrix,coordinate_mapping[,3])


population_values = runif(length(unique_node_id),0,max(triangle_population))


write.table(population_values,file="../Output/population_values.csv",row.names=FALSE,col.names=FALSE,sep=",")

