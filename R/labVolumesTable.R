#' Function to generate clean text file of sample amounts for lab
#' 
#' This function accepts a vector of storm names, vector of storm start and end datetimes and list of dataframes containing event data
#' 
#' @param StormName vector of storm name(s)
#' @param StormStart vector of storm start dates
#' @param StormEnd vector of storm end dates
#' @param tableOut list of data frames containing event data
#' @param bottlePickup date bottles were retrieved
#' @export
labVolumesTable <- function(StormName,StormStart,StormEnd,tableOut,bottlePickup){
  fileName <- paste(StormName[1],"labVolumes",".txt",sep="")
  sink(fileName)
  for (i in 1:length(StormName)) {
    cat("==================================================================================","\n")
    cat("\t",StormName[i],"\t\t",strftime(StormStart[i]),"\t",strftime(StormEnd[i]),"\n")
    cat("==================================================================================","\n")
    labTable <- tableOut[[i]]
    for (j in 1:nrow(labTable)) {
      cat("\t",labTable$subNum[j],"\t",strftime(labTable$datetime[j]),"\t",labTable$mL[j],"\n")
    }
    cat("==================================================================================","\n")
    cat("\t","Bottles ",tableOut[[i]]$subNum[1]," through ",tableOut[[i]]$subNum[length(tableOut[[i]]$subNum)]," picked up ",bottlePickup,"\n")
    cat("==================================================================================","\n")
  }
  sink()
}