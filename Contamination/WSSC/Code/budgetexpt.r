hybrid_cov = read.csv("./budgetExpt/hybrid_coverage_results.csv",header=FALSE) # 3 column 
hybrid_imp = read.csv("./budgetExpt/hybrid_impact_results.csv",header=FALSE)  # 3 column
static_cov = read.csv("./budgetExpt/pure_static_coverage_results.csv",header=FALSE) # 1 column (only static)
static_imp = read.csv("./budgetExpt/pure_static_impact_results.csv",header=FALSE)  # 2 column (name, coverage)
static_cov = static_cov$V1
static_cov = as.numeric(static_cov)

total = 299

hcd_cost = c()
hcd_coverage = c()

hid_cost = c()
hid_coverage = c()

scd_cost = c()
scd_coverage = c()

sid_cost = c()
sid_coverage = c()

init_perc = 0.1

for(i in 1:10)
{
	number_of_indices = ceiling(init_perc * length(hybrid_cov[,1]))

	temp_cost = (length(which(hybrid_cov[1:number_of_indices,2] == 1)) * 5) + (length(which(hybrid_cov[1:number_of_indices,2] == 0)) * 1)
	hcd_cost = c(hcd_cost,temp_cost)
	temp_coverage = ((hybrid_cov[number_of_indices,3]) / total)
	hcd_coverage = c(hcd_coverage,temp_coverage)
	


	number_of_indices = ceiling(init_perc * length(hybrid_imp[,1]))

	temp_cost = (length(which(hybrid_imp[1:number_of_indices,2] == 1)) * 5) + (length(which(hybrid_imp[1:number_of_indices,2] == 0)) * 1)
	hid_cost = c(hid_cost,temp_cost)
	temp_coverage = ((hybrid_imp[number_of_indices,3]) / total)
	hid_coverage = c(hid_coverage,temp_coverage)

	
	number_of_indices = ceiling(init_perc * length(static_cov))
	scd_cost = c(scd_cost,(number_of_indices * 5))
	temp_coverage = ((static_cov[number_of_indices]) / total)
	scd_coverage = c(scd_coverage,temp_coverage)

	number_of_indices = ceiling(init_perc * length(static_imp[,1]))
	sid_cost = c(sid_cost,(number_of_indices * 5))
	temp_coverage = ((static_imp[number_of_indices,2]) / total)
	sid_coverage = c(sid_coverage,temp_coverage)

	init_perc = init_perc + 0.1
	
}

# row_names = c("10%","20%","30%","40%","50%","60%","70%","80%","90%","100%")

final_df = data.frame(sid_cost,hid_cost,scd_cost,hcd_cost,sid_coverage,hid_coverage,scd_coverage,hcd_coverage)
colnames(final_df) = c("sidCost","hidCost","scdCost","hcdCost","sidCov","hidCov","scdCov","hcdCov")

write.table(final_df,file="./budgetExpt/final_results.csv",row.names=FALSE,sep=",")


