#' Function to generate text file with storm event sample bottle volume table(s) and extra info 
#' 
#' This function accepts a vector of storm names, vector of storm start and end datetimes, vector of comments (optional) and list of dataframes containing event data
#' 
#' @param StormName vector of storm name(s)
#' @param StormStart vector of storm start dates
#' @param StormEnd vector of storm end dates
#' @param tableOut list of data frames containing event data
#' @param maxBottleVol maximum bottle volume
#' @param bottlePickup date bottles were retrieved
#' @param removeComment vector of comments
#' @export
stormEventsTable <- function(StormName,StormStart,StormEnd,tableOut,maxBottleVol,bottlePickup,removeComment=""){
  fileName <- paste(StormName[1],"sampVol",".txt",sep="")
  volSum <- 0
  less <- 0
  sink(fileName)
  for (i in 1:length(StormName)) {
    if (!is.na(tableOut[[i]][1,2])) {
    cat(StormName[i],"\t",strftime(StormStart[i],format="%Y-%m-%d %H:%M"),"\t",strftime(StormEnd[i],format="%Y-%m-%d %H:%M"),"\n\n")
    tableOut[[i]][,"datetime"] <- strftime(tableOut[[i]][,"datetime"],format="%Y-%m-%d %H:%M %z", tz=attr(tableOut[[i]][,"datetime"],"tzone"))
    tableOut[[i]][,"sampStar"] <- strftime(tableOut[[i]][,"sampStar"],format="%Y-%m-%d %H:%M")
    tableOut[[i]][,"sampEnd"] <- strftime(tableOut[[i]][,"sampEnd"],format="%Y-%m-%d %H:%M")
    print(tableOut[[i]],row.names=FALSE)
    cat("\n\n")
    cat("Lab Sample Volume","\t",sum(tableOut[[i]]$mL),"mL\t",sum(tableOut[[i]]$perc),"percent\n\n")
    cat("Max Bottle Volume","\t",maxBottleVol[i-less],"mL\n\n")
    cat("Total subsample bottles","\t",nrow(tableOut[[i]]),"\n\n")
    cat("Max Optimized Bottle Volume","\t",max(tableOut[[i]]$mL),"mL\n\n")
    cat("Max Sample Runoff Volume","\t",max(tableOut[[i]]$volume),"cubic feet\n\n")
    cat("Total Sampled Storm Volume","\t",sum(tableOut[[i]]$volume),"cubic feet\n\n")
    cat(bottlePickup[i-less],"\n\n")
    if (!is.na(removeComment[i])) {cat(removeComment[i],"\n\n")}
    volSum <- sum(tableOut[[i]]$volume) + volSum
    cat("========================================================================================================","\n\n")
    } else {
      less <- less+1
      cat(StormName[i],"\t",strftime(StormStart[i],format="%Y-%m-%d %H:%M"),"\t",strftime(StormEnd[i],format="%Y-%m-%d %H:%M"),"\n\n")
      cat("Total Sampled Storm Volume","\t",sum(tableOut[[i]]$volume),"cubic feet\n\n")
      volSum <- sum(tableOut[[i]]$volume) + volSum
      cat("========================================================================================================","\n\n")
    }
  }
  cat("Total Storm Volume from subs",volSum,"\n\n")
  cat("Total Storm Volume", sum(tableOut[[length(tableOut)]]$volume),"\n\n")
  sink()
}