###################################
########## Practical 5.1 ##########
###################################
data("austri1autoBI7895", package = "CASdatasets")

#We index with j from 1 to J instead of from 0 to J'

#########
### a ###
#########

source("11 StatIns/Exercises/Week 10/MackChainLadderMethod.R")

MackCLEstimation <- MackChainLadderMethod(austri1autoBI7895$paid)
MackCLEstimation$TotalUltimate
MackCLEstimation$Reserve



#########
### b ###
#########
source("11 StatIns/Exercises/Week 10/BornhuetterFergusonMethod.R")

BFEstimation <- BornhuetterFergusonMethod(austri1autoBI7895$paid, austri1autoBI7895$expo)
BFEstimation$TotalUltimates



#########
### c ###
#########

MackCLEstimation$conditionalVariance
MackCLEstimation$bias^2
MackCLEstimation$MSE
