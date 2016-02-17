#' Function to generate clean text file of sample amounts for lab
#' 
#' This function accepts a vector of storm names, vector of storm start and end datetimes and list of dataframes containing event data
#' 
#' @param StormName vector of storm name(s)
#' @param StormStart vector of storm start dates
#' @param StormEnd vector of storm end dates
#' @param tableOut list of data frames containing event data
#' @param bottlePickup dates bottles were retrieved
#' @export
labVolumesTable <- function(StormName,StormStart,StormEnd,tableOut,bottlePickup){
  fileName <- paste(StormName[1],"labVolumes",".txt",sep="")
  less <- 0
  sink(fileName)
  for (i in 1:length(StormName)) {
    if (!is.na(tableOut[[i]][1,2])) {
    cat("==================================================================================","\n")
    cat("\t",StormName[i],"\t\t",strftime(StormStart[i],format="%Y-%m-%d %H:%M"),"\t",strftime(StormEnd[i],format="%Y-%m-%d %H:%M"),"\n")
    cat("==================================================================================","\n")
    labTable <- tableOut[[i]]
    for (j in 1:nrow(labTable)) {
      cat("\t",paste0(labTable$subNum[j],paste0(rep(" ",max(nchar(labTable$subNum))),collapse=""),collapse=""),"\t",strftime(labTable$datetime[j],format="%Y-%m-%d %H:%M %z", tz=attr(labTable$datetime,"tzone")),"\t",labTable$mL[j],"\n")
    }
    cat("==================================================================================","\n")
    cat("\t",bottlePickup[i-less],"\n")
    cat("==================================================================================","\n")
    } else {less<-less+1}
  }
  sink()
}