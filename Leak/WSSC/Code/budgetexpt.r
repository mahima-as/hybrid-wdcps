hybrid_cov = read.csv("./budgetExpt/hybrid_coverage_results.csv",header=FALSE) # 3 column 
hybrid_imp = read.csv("./budgetExpt/hybrid_impact_results.csv",header=FALSE)  # 3 column
static_cov = read.csv("./budgetExpt/pure_static_coverage_results.csv",header=FALSE) # 1 column (only static)
static_imp = read.csv("./budgetExpt/pure_static_impact_results.csv",header=FALSE)  # 2 column (name, coverage)


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
	

	
}


