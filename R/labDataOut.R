#' Function to return adaps_lab_samples df derived from previously merged data
#' 
#' This function accepts a data frame of data for a site/storm event, storm start dates, storm end dates, 
#' storm names, maximum volume in one sample bottle, and maximum volume for an entire storm sample
#' 
#' @param adaps_data_all data frame containing merged ADAPS data for the requested site and date range
#' @param StormStart vector of datetimes for storm starts
#' @param StormEnd vector of datetime for storm ends
#' @param StormName vector of storm names
#' @param maxBottleVol vector of maximum volumes in one subsample bottle
#' @param maxSampVol vector of maximum volumes of one total sample
#' @param removeDate vector of datetimes to be removed from the calculation, in the same timezone as adaps_data_all$datetime
#' @param subNum vector of starting numbers for first bottle of each storm event
#' @return tableOut list of a table for each storm event of bottle volumes 
#' @import googleVis
#' @export
#' @examples
#' rdbExample<-rdbExample
#' maxBottleVol <- c(400,600,600,600,600,600,600,400,600,800)
#' maxSampVol <- c(3900,3900,3900,3900,3900,3900,3900,3900,3900,3900)
#' StormStart <- c("2008-05-30 02:51","2008-06-05 04:39","2008-06-06 04:22","2008-06-07 22:52","2008-06-08 08:41","2008-06-08 19:03","2008-06-12 09:03","2008-06-12 21:40","2008-06-14 16:52","2008-06-15 04:07")
#' StormEnd <- c("2008-05-30 08:49","2008-06-05 07:21","2008-06-06 05:28","2008-06-08 01:14","2008-06-08 11:39","2008-06-08 21:31","2008-06-12 10:22","2008-06-13 01:36","2008-06-14 18:05","2008-06-15 09:22")
#' StormName <- c("S2-066","S2-067","S2-068","S2-069","S2-070","S2-071","S2-072","S2-073","S2-074","S2-075")
#' subNum <- c(1,1,1,1,16,1,1,5,1,7)
#' dataOut <- labDataOut(rdbExample,StormStart,StormEnd,StormName,maxBottleVol,maxSampVol)
#' removeDate <- as.POSIXct("2008-06-15 05:44:00")
#' dataOut2 <- labDataOut(rdbExample,StormStart,StormEnd,StormName,maxBottleVol,maxSampVol, removeDate)
labDataOut <- function(adaps_data_all,StormStart,StormEnd,StormName,maxBottleVol,maxSampVol,removeDate=NA,subNum=-9) {
  adaps_data_samples <- adaps_data_all[which(adaps_data_all$p99234>0),c("datetime","p00060")]
  adaps_data_plot <- adaps_data_all[,c("datetime","p00065","p00060")]
  StormStart <- as.POSIXct(StormStart,format="%Y-%m-%d %H:%M", tz=tzCode)
  StormEnd <- as.POSIXct(StormEnd,format="%Y-%m-%d %H:%M", tz=tzCode)
  if (sum(is.na(StormStart))+sum(is.na(StormEnd))>0) {
    cat(paste("Problem with date format","\n\n",sep=""))
  } else {
    tableOut <- list()
    numStorms <- length(StormStart)
    noSamp <- 0
    for (j in 1:numStorms) {
      StartDt <- as.POSIXct(StormStart[j],tz=tzCode)
      EndDt <- as.POSIXct(StormEnd[j],tz=tzCode)
      row.names(adaps_data_plot)<-(1:nrow(adaps_data_plot))
      startRow <- as.character(as.numeric(row.names(adaps_data_plot[which(StartDt==adaps_data_plot$datetime),]))-1)
      endRow <- as.character(as.numeric(row.names(adaps_data_plot[which(EndDt==adaps_data_plot$datetime),]))+1)
      adaps_data_storm <- adaps_data_plot[startRow:endRow,]
      adaps_data_storm <- adaps_data_storm[which(!is.na(adaps_data_storm$p00060)),]
      data_rows <- nrow(adaps_data_storm)
      adaps_data_storm$volume <- 9999
      for (i in 1:data_rows) {
        if (i>1) {
          if (i<data_rows) {
            
            adaps_data_storm$volume[i] <- (.5*(as.numeric(difftime(adaps_data_storm$datetime[i],adaps_data_storm$datetime[i-1],units="secs")))*(.75*adaps_data_storm$p00060[i]+.25*adaps_data_storm$p00060[i-1]))+(.5*(as.numeric(difftime(adaps_data_storm$datetime[i+1],adaps_data_storm$datetime[i],units="secs")))*(.75*adaps_data_storm$p00060[i]+.25*adaps_data_storm$p00060[i+1]))
          } else {
            adaps_data_storm$volume[i] <- NA
          }
        } else {adaps_data_storm$volume[i] <- NA}
      }
      adaps_samp_storm <- adaps_data_samples[which(StartDt<=adaps_data_samples$datetime&adaps_data_samples$datetime<=EndDt),]
      if (nrow(adaps_samp_storm)==0) {
        cat(paste(StormName[j],"Storm event specified which has no samples","\n",sep=" "))
       adaps_data_storm_nosamp <- adaps_data_storm[which(StartDt<=adaps_data_storm$datetime&adaps_data_storm$datetime<=EndDt),]
       adaps_data_storm_nosamp$samplesNum <- StormName[j]
       adaps_samp_storm <- data.frame("No samples for event",NA,NA,NA,sum(adaps_data_storm_nosamp$volume,na.rm=TRUE),StartDt,EndDt,stringsAsFactors=FALSE)
       colnames(adaps_samp_storm) <- c("subNum","datetime","mL","perc","volume","sampStar","sampEnd")
       noSamp <- noSamp+1
       adaps_data_samp <- if (j>1) {rbind(adaps_data_samp,adaps_data_storm_nosamp)} else {adaps_data_storm_nosamp}
      } else {
      maxBottleV <- maxBottleVol[j-noSamp]
      maxSampV <- maxSampVol[j-noSamp]
      if (subNum[1]>0) {subStart<-subNum[j-noSamp]} else {subStart<-1}
      subMax <- nrow(adaps_samp_storm)+(subStart-1)
      adaps_samp_storm$subNum <- c(subStart:subMax)
      adaps_samp_storm$subNum <- paste(StormName[j],adaps_samp_storm$subNum,sep="-")
      if (any(adaps_samp_storm$datetime %in% removeDate)) {
        # removeDate <- strptime(removeDate,format="%Y-%m-%d %H:%M")
        numSamples <- nrow(adaps_samp_storm)
        # for (i in 1:length(removeDate)) {
        #   adaps_samp_storm <- adaps_samp_storm[which(adaps_samp_storm$datetime!=removeDate[i]),]
        # }
        adaps_samp_storm <- adaps_samp_storm[-which(adaps_samp_storm$datetime %in% removeDate),]
        if (nrow(adaps_samp_storm)<numSamples){
          cat(paste0(numSamples-nrow(adaps_samp_storm)," samples removed","\n"))
                                               cat(paste0(removeDate,"\n"))
        }
      }
      adaps_samp_storm$volume <- 9999
      adaps_samp_storm$sampStar <- as.POSIXct(StartDt, tz=tzCode)
      adaps_samp_storm$sampEnd <- as.POSIXct(EndDt, tz=tzCode)
      samplesNum <- nrow(adaps_samp_storm)
      for (i in 1:samplesNum) {
        sampStart <- if (i>1) {adaps_samp_storm$datetime[i-1]+(.5*(adaps_samp_storm$datetime[i]-adaps_samp_storm$datetime[i-1]))} else {min(adaps_data_storm$datetime)}
        sampEnd <- if (i<samplesNum) {adaps_samp_storm$datetime[i]+(.5*(adaps_samp_storm$datetime[i+1]-adaps_samp_storm$datetime[i]))} else {max(adaps_data_storm$datetime)}
        adaps_data_storm_temp <- adaps_data_storm[which(adaps_data_storm$datetime>=sampStart&adaps_data_storm$datetime<=sampEnd),]
        if (nrow(adaps_data_storm[which(adaps_data_storm$datetime==sampEnd),])>0) {
          adaps_data_storm_temp$volume[nrow(adaps_data_storm_temp)] <- 0.5*(adaps_data_storm_temp$volume[nrow(adaps_data_storm_temp)])
          sampEndOut <- if (i<samplesNum) {sampEnd + 0.5*(min(adaps_data_storm$datetime[which(adaps_data_storm$datetime>sampEnd)])-sampEnd)} else {max(adaps_data_storm$datetime)}
        } else {sampEndOut <- max(adaps_data_storm$datetime[which(adaps_data_storm$datetime<sampEnd)])}
        if (nrow(adaps_data_storm[which(adaps_data_storm$datetime==sampStart),])>0) {
          adaps_data_storm_temp$volume[1] <- 0.5*(adaps_data_storm_temp$volume[1])
          sampStartOut <- if (i>1) {sampStart + 0.5*(min(adaps_data_storm$datetime[which(adaps_data_storm$datetime>sampStart)])-sampStart)} else {min(adaps_data_storm$datetime)}
        } else {sampStartOut <- min(adaps_data_storm$datetime[which(adaps_data_storm$datetime>sampStart)])}
        adaps_samp_storm$volume[i] <- sum(adaps_data_storm_temp$volume,na.rm=TRUE)
        adaps_data_storm_temp$datetime[1] <- sampStartOut
        adaps_data_storm_temp$datetime[nrow(adaps_data_storm_temp)] <- sampEndOut
        adaps_samp_storm$sampStar[i] <- as.POSIXct(sampStartOut, tz=tzCode)
        adaps_samp_storm$sampEnd[i] <- as.POSIXct(sampEndOut, tz=tzCode)
        adaps_samp_storm$subNum[i] <- paste(strsplit(adaps_samp_storm$subNum[i],"-")[[1]][1],strsplit(adaps_samp_storm$subNum[i],"-")[[1]][3],sep="-")
        adaps_data_storm_temp$samplesNum <- rep(adaps_samp_storm$subNum[i],nrow(adaps_data_storm_temp))
        adaps_data_samp <- if (i+j>2) {rbind(adaps_data_samp,adaps_data_storm_temp)} else {adaps_data_storm_temp}
      }
      adaps_data_samp <- subset(adaps_data_samp, !is.na(adaps_data_samp$volume))
      adaps_samp_storm <- subset(adaps_samp_storm, !is.na(adaps_samp_storm$volume))
      adaps_samp_storm$perc <- round(100*(adaps_samp_storm$volume/sum(adaps_data_storm$volume,na.rm=TRUE)),digits=1)
      adaps_samp_storm$mL <- adaps_samp_storm$volume*maxBottleV/max(adaps_samp_storm$volume,na.rm=TRUE)
      if (sum(adaps_samp_storm$mL,na.rm=TRUE)>maxSampV) {
        currSum <- sum(adaps_samp_storm$mL,na.rm=TRUE)
        adaps_samp_storm$mL <- trunc(adaps_samp_storm$mL*(maxSampV/currSum))
      } else { adaps_samp_storm$mL <- trunc(adaps_samp_storm$mL)}
      }
      tableOut[[j]] <- adaps_samp_storm[,c("subNum","datetime","mL","perc","volume","sampStar","sampEnd")]
    }
    tableOut[[j+1]] <- adaps_data_samp
  }
  return(tableOut)
}
