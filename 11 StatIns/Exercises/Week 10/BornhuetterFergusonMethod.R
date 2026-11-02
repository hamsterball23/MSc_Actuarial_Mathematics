source("11 StatIns/Exercises/Week 10/MackChainLadderMethod.R")

BornhuetterFergusonMethod <- function(incrTri, expo)
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

  mackCL <- MackChainLadderMethod(incrTri)

  kappa <- mackCL$kappa

  expoTri <- expo[rownames(incrTri)]
  prior = ifelse(kappa > 0.8, mackCL$TotalUltimate, 0.37 * expoTri)

  TotalUltimates <- kappa * mackCL$TotalUltimate + (1-kappa)*prior

  return(
    structure(
      list(
        TotalUltimates = TotalUltimates,
        prior = prior,
        kappa = kappa,
        mackCL = mackCL
      ),
      class = "BornhuetterFergusonEstimate"
    )
  )
}