MackChainLadderMethod <- function(incrTri)
{
  I <- nrow(incrTri)
  J <- ncol(incrTri)

  if (I < J){
    stop(
      paste(
        "Need at least as many accident years as development periods (here ",
        I, " rows and ", J, " columns)."
      )
    )
  }

  ### --- Create cumulative Triangle ---
  C <- incrTri
  for (i in 1:I){
    #First increment is also first cumulative
    for (j in 2:J){
      C[i, j] <- C[i, j-1] + incrTri[i, j]
    }
  }

  ### --- Development factors ---
  f <- rep(NA, J)

  # We index f by the same as above - index 1 is the factor to multiple C_{i,1} to get C_{i,2}
  for (j in 1:(J-1))
  {
    f[j] <- sum(C[1:(I-j),j+1]) / sum(C[1:(I-j),j]) 
  }


  ### --- Variance factors ---
  # s[j] needs at least two observed link ratios, i.e. I-j >= 2
  s <- rep(NA, J)
  for (j in 1:min(J-1, I-2)){
    s[j] <- sqrt(
      sum(C[1:(I-j),j] * (C[1:(I-j),j+1] / C[1:(I-j),j] - f[j])**2) / (I-j-1)
    )
  }

  # Mack amendment - only needed for a true triangle (one observation of the last period)
  if (I == J){
    s[J-1] <- sqrt(
      min(
        s[J-3]^2,
        (s[J-2]^4) / (s[J-3]^2)
      )
    )
  }

  ### (a) --- Estimated total ultimate and reserve ---

  # Last observed development period for each accident year (J for the first I-J+1 years)
  lastObs <- pmin(J, I + 1 - (1:I))

  #Estimate total ultimate and reserve
  # The first I-J+1 rows are fully developed, so their cumulative factor is 1
  cumRecent <- C[cbind(1:I, lastObs)]
  cumulativefFactors <- c(rep(1, I-J+1), cumprod(rev(f[1:(J-1)])))

  FullEstimatedCumulatives <- C

  for (j in 2:J){
    for (i in I:(I-j+2)){
      FullEstimatedCumulatives[i,j] <- FullEstimatedCumulatives[i,j-1] * f[j-1]
    }
  }

  TotalUltimate <- cumRecent * cumulativefFactors
  ReserveForEachYear <- TotalUltimate - cumRecent
  Reserve <- sum(ReserveForEachYear)

  ### (c) --- Conditional variance, squared bias and conditional MSE ---

  # Only rows I-J+2, ..., I are not fully developed
  conditionalVariance <- rep(0, I)
  for (i in (I-J+2):I){
    js <- lastObs[i]:(J-1)
    conditionalVariance[i] <- FullEstimatedCumulatives[i,J]^2 *
      sum((s[js]^2 / f[js]^2) / FullEstimatedCumulatives[i,js])
  }

  # Column sums used in f[j] (denominator of the bias term) below
  colSumsF <- sapply(1:(J-1), function(j) sum(C[1:(I-j), j]))

  bias <- rep(0, I)
  for (i in (I-J+2):I){
    js <- lastObs[i]:(J-1)
    bias[i] <- sqrt(
      FullEstimatedCumulatives[i,J]^2 *
      sum(s[js]^2 / f[js]^2 / colSumsF[js])
    )
  }

  MSE <- conditionalVariance + bias^2


  return(
    structure(
      list(
        TotalUltimate = TotalUltimate,
        FullEstimatedCumulatives = FullEstimatedCumulatives,
        ReserveForEachYear = ReserveForEachYear,
        Reserve = Reserve,
        conditionalVariance = conditionalVariance,
        bias = bias,
        MSE = MSE,
        cumulativefFactors = cumulativefFactors,
        kappa = 1 / cumulativefFactors,
        f = f,
        s = s
      ),
      class = "MackChainLadderEstimate"
    )
  )
}