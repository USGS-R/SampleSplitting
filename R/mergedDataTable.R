#' Function to save merged data for station/storm event, saved as file, eg 434425090462401data.txt 
#' 
#' This function accepts a siteNo, StartDt and EndDt and merged data data frame for a storm event, and generates a data file
#' 
#' @param siteNo USGS station id
#' @param StartDt start of storm event
#' @param EndDt end of storm event
#' @param adaps_data_all data frame of event data
#' @export
#' @importFrom utils write.table
mergedDataTable <- function(siteNo,StartDt,EndDt,adaps_data_all) {  
  names(adaps_data_all)[names(adaps_data_all) == "dateTime"] <- "datetime"
  
  fileName <- paste(siteNo,"data.csv",sep="")
  sink(fileName)
  cat("Station:"," ",siteNo,"\t",
      "Start date:"," ",strftime(StartDt,format="%Y-%m-%d", tz=attr(adaps_data_all$datetime,"tzone")),"\t",
      "End date:"," ",strftime(EndDt,format="%Y-%m-%d", tz=attr(adaps_data_all$datetime,"tzone")),"\n\n")
  write.table(adaps_data_all,file="",sep=",",row.names=FALSE)
  sink()
}


