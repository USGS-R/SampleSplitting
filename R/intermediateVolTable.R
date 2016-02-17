#' Function to csv file of all intermediate volumes used for calculations 
#' 
#' This function accepts a siteNo, StartDt, EndDt and tableOut list of data for a given storm event
#' 
#' @param siteNo USGS station id
#' @param StartDt start of storm event
#' @param EndDt end of storm event
#' @param tableOut list of data frames of event data
#' @export
intermediateVolTable <- function(siteNo,StartDt,EndDt,tableOut){
  fileName <- paste0(siteNo,"SampleVols.csv")
  tzAttr <- attr(tableOut[[i]][,"datetime"],"tzone")
  for(i in seq(length(tableOut))){
    tableOut[[i]][,"datetime"] <- strftime(tableOut[[i]][,"datetime"],format="%Y-%m-%d %H:%M %z", tz=tzAttr)
  }
  sink(fileName)
  cat("Station:"," ",siteNo,"\t","Start date:"," ",strftime(as.POSIXct(StartDt), tz=tzAttr),"\t","End date:"," ",strftime(as.POSIXct(EndDt), tz=tzAttr),"\n\n")
  write.table(tableOut[[length(tableOut)]],file="",sep=",",row.names=FALSE)
  sink()
}