#' Function to return adaps_data_all df from NWISWeb or previously retrieved RDB files
#' 
#' This function accepts an NWIS gage site id, an NWIS precip site id, a StartDate, an EndDate, a timezone and file names as needed
#' 
#' @param siteNo NWIS gaging station id
#' @param precipSite NWIS precipitation station id
#' @param StartDt a date to start data pulls
#' @param EndDt a date to end data pulls
#' @param tzCode a timezone specification for the data
#' @param dataFile string of data file path and name
#' @return adaps_data_all data frame containing merged ADAPS data for the requested site and date range
#' @import dataRetrieval
#' @export
#' @examples
#' \dontrun{
#' siteNo <- "424421077495301"
#' StartDt <- '2016-02-03'
#' EndDt <- '2016-02-03'
#' precipSite <- "424421077495301"
#' tzCode <- "America/Jamaica"
#' adaps_data_all <- getADAPSData(siteNo,StartDt,EndDt,precipSite,tzCode=tzCode)
#' }
getADAPSData <- function(siteNo,StartDt,EndDt,precipSite,dataFile="",tzCode="") {
  
  if (nchar(dataFile)>=3) {
    adaps_data_in <- read.delim(dataFile,header=TRUE,quote="\"",dec=".",sep="\t",colClasses=c("character"),strip.white=TRUE,fill=TRUE,comment.char="#")
    adaps_data_in <- adaps_data_in[-1, ]
    adaps_data_in$datetime <- as.POSIXct(strptime(paste(adaps_data_in$YEAR,sprintf("%02d",as.numeric(adaps_data_in$MONTH)),sprintf("%02d",as.numeric(adaps_data_in$DAY)),sprintf("%02d",as.numeric(adaps_data_in$MINUTE)%/%60),sprintf("%02d",as.numeric(adaps_data_in$MINUTE)%%60),sep=""),"%Y%m%d%H%M"))
    adaps_data_in$pcode <- substr(adaps_data_in$NAME,mean(nchar(adaps_data_in$NAME))-4,mean(nchar(adaps_data_in$NAME)))
    adaps_scode <- adaps_data_in[which(adaps_data_in$pcode=="99234"),c("datetime","VALUE")]
    colnames(adaps_scode) <- c("datetime","p99234")
    adaps_scode$p99234 <- as.numeric(adaps_scode$p99234)
    adaps_scode <- subset(adaps_scode,adaps_scode$p99234>900)
    adaps_stage <- adaps_data_in[which(adaps_data_in$pcode=="00065"),c("datetime","VALUE")]
    colnames(adaps_stage) <- c("datetime","p00065")
    adaps_precip <- adaps_data_in[which(adaps_data_in$pcode=="00045"),c("datetime","VALUE")]
    colnames(adaps_precip) <- c("datetime","p00045")
    adaps_disch <- adaps_data_in[which(adaps_data_in$pcode=="00060"),c("datetime","VALUE")]
    colnames(adaps_disch) <- c("datetime","p00060")
    
    adaps_data <- merge(adaps_stage,adaps_disch,by="datetime",all=T)
    adaps_data <- merge(adaps_precip,adaps_data,by="datetime",all=T)
    adaps_data <- merge(adaps_scode,adaps_data,by="datetime",all=T)
    adaps_data$p00065 <- as.numeric(adaps_data$p00065)
    adaps_data$p00060 <- as.numeric(adaps_data$p00060)
    adaps_data$p00045 <- as.numeric(adaps_data$p00045)
    adaps_data_all <- data.frame(adaps_data,rep("USGS",nrow(adaps_data)),rep(siteNo,nrow(adaps_data)),stringsAsFactors=FALSE)
    colnames(adaps_data_all) <- c("datetime","p99234","p00045","p00065","p00060","agency_cd","site_no")
    for (i in 1:nrow(adaps_data_all)) {
      adaps_data_all$cum_00045[i] <- sum(adaps_data_all$p00045[1:i],na.rm=TRUE)
    }
    return(adaps_data_all)
  } else {
    POR <- paramAvailability(siteNo)
    POR <- POR[which(POR$service=="uv" & POR$parameter_cd %in% c("00060","00065","99234")),]
    PORprecip <- paramAvailability(precipSite)
    PORprecip <- PORprecip[which(PORprecip$service=="uv"&PORprecip$parameter_cd=="00045"),]
    
    if(is.null(getOption("Access.dataRetrieval"))){
      setAccess("internal")
    }

    if ((length(unique(POR$parameter_cd)))+(length(unique(PORprecip$parameter_cd)))>=4) {
      if (max(POR$startDate[which(POR$service=="uv"&POR$parameter_cd %in% c("00060","00065"))])<=StartDt&min(POR$endDate[which(POR$service=="uv"&POR$parameter_cd %in% c("00060","00065"))])>=EndDt) {
        if (as.Date(StartDt,"%Y-%m-%d")<=(Sys.Date()-120)) {type<-"uv"} else {type<-"iv"}
        stage_url <- constructNWISURL(siteNo,'00065',StartDt,EndDt,type,format="tsv")
        # stage_url <- paste(stage_url,"&access=",max(POR$status[which(POR$parameter_cd=="00065")]),sep="")
        adaps_stage_in <- importRDB1(stage_url,asDateTime=TRUE,tz=tzCode)
        colnames(adaps_stage_in) <- c("agency_cd","site_no","datetime","tz_cd","p00065","p00065_cd")
        disch_url <- constructNWISURL(siteNo,'00060',StartDt,EndDt,type,format="tsv")
        # disch_url <- paste(disch_url,"&access=",max(POR$status[which(POR$parameter_cd=="00060")]),sep="")
        adaps_disch_in <- importRDB1(disch_url,asDateTime=TRUE,tz=tzCode)
        colnames(adaps_disch_in) <- c("agency_cd","site_no","datetime","tz_cd","p00060","p00060_cd")
        if (siteNo!=precipSite) {
          precip_url <- constructNWISURL(precipSite,'00045',StartDt,EndDt,type,format="tsv")
          # precip_url <- paste(precip_url,"&access=",max(PORprecip$status),sep="")
          adaps_precip_in <- importRDB1(precip_url,asDateTime=TRUE,tz=tzCode)
          colnames(adaps_precip_in) <- c("agency_cd","site_no","datetime","tz_cd","p00045","p00045_cd")
        } else {
          precip_url <- constructNWISURL(precipSite,'00045',StartDt,EndDt,type,format="tsv")
          # precip_url <- paste(precip_url,"&access=",max(PORprecip$status),sep="")
          adaps_precip_in <- importRDB1(precip_url,asDateTime=TRUE,tz=tzCode)
          colnames(adaps_precip_in) <- c("agency_cd","site_no","datetime","tz_cd","p00045","p00045_cd")
        }
        scode_url <- constructNWISURL(siteNo,'99234',StartDt,EndDt,type,format="tsv")
        # scode_url <- paste(scode_url,"&access=",max(POR$status[which(POR$parameter_cd=="99234")]),sep="")
        adaps_scode_in <- importRDB1(scode_url,asDateTime=TRUE,tz=tzCode)
        colnames(adaps_scode_in) <- c("agency_cd","site_no","datetime","tz_cd","p99234","p99234_cd")
        adaps_scode_in <- subset(adaps_scode_in,adaps_scode_in$p99234>900)
        adaps_data<-merge(adaps_stage_in[c(1,2,3,5)],adaps_disch_in[c(3,5)],by="datetime",all=T)
        adaps_data<-merge(adaps_precip_in[c(3,5)],adaps_data,by="datetime",all=T)
        adaps_data_all <- merge(adaps_data,adaps_scode_in[c(3,5)],by="datetime",all=T)
        colnames(adaps_data_all) <- c("datetime","p00045","agency_cd","site_no","p00065","p00060","p99234")
        for (i in 1:nrow(adaps_data_all)) {
          adaps_data_all$cum_00045[i] <- sum(adaps_data_all$p00045[1:i],na.rm=TRUE)
        }
        return(adaps_data_all)
      }
    } else {
      cat(paste("ADAPS data not available via NWISWeb for selected site, date range and parameter codes","\n",sep=""))
      cat(paste("Available period of record follows: ","\n",sep=""))
      PORAll <- rbind(POR,PORprecip)
      print(PORAll[,c("parameter_cd","startDate","endDate","count","parameter_nm")],row.names=FALSE)} 
    }
  }


.onAttach <- function(libname, pkgname) {
  packageStartupMessage("Although this software program has been used by the U.S. Geological Survey (USGS), no warranty, expressed or implied, is made by the USGS or the U.S. Government as to the accuracy and functioning of the program and related program material nor shall the fact of distribution constitute any such warranty, and no responsibility is assumed by the USGS in connection therewith.")
}