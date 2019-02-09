detectionTime = read.csv("../Output/detectionTime.csv",header=FALSE)

detectionTimeArray = as.matrix(detectionTime)
class(detectionTimeArray) = "numeric"
detectionTimeArray = as.vector(detectionTimeArray)
detectionTimeArray = detectionTimeArray[which(is.finite(detectionTimeArray) & detectionTimeArray != 0)]
minval = min(detectionTimeArray)
maxval = max(detectionTimeArray)
detectionTime = as.matrix(detectionTime)
class(detectionTime) = "numeric"
for(i in 1:length(detectionTime[,1]))
{
	current_row = detectionTime[i,]
	indices = which(!(is.finite(current_row) & current_row!=0))
	for(j in 1:length(indices))
	{
		current_row[indices[j]] = runif(1,minval,maxval)
	}
	detectionTime[i,] = current_row
}

write.table(detectionTime, file = "../Output/detectionTime1.csv",row.names=FALSE, col.names=FALSE, sep=",")

detectionTime = read.csv("../Output/traversalTime.csv",header=FALSE)
detectionTimeArray = as.matrix(detectionTime)
class(detectionTimeArray) = "numeric"
detectionTimeArray = as.vector(detectionTimeArray)
detectionTimeArray = detectionTimeArray[which(is.finite(detectionTimeArray) & detectionTimeArray != 0)]
minval = min(detectionTimeArray)
maxval = max(detectionTimeArray)
detectionTime = as.matrix(detectionTime)
class(detectionTime) = "numeric"
for(i in 1:length(detectionTime[,1]))
{
	current_row = detectionTime[i,]
	indices = which(!(is.finite(current_row) & current_row!=0))
	for(j in 1:length(indices))
	{
		current_row[indices[j]] = runif(1,minval,maxval)
	}
	detectionTime[i,] = current_row
}

write.table(detectionTime, file = "../Output/traversalTime1.csv",row.names=FALSE, col.names=FALSE, sep=",")