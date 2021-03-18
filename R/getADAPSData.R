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
      if (max(POR$startDate[which(POR$service == "uv" & POR$parameter_cd %in% c("00060","00065"))]) <= StartDt &
          min(POR$endDate[which(POR$service == "uv" & POR$parameter_cd %in% c("00060","00065"))]) >= EndDt) {
        
        adaps_data <- readNWISuv(siteNumbers = unique(c(siteNo, precipSite)), 
                                parameterCd = c('00065', '00060', '99234', '00045'),
                                startDate = StartDt,
                                endDate = EndDt,
                                tz = tzCode)
        adaps_data <- renameNWISColumns(adaps_data, p99234 = "Count")
        names(adaps_data)[names(adaps_data) == "dateTime"] <- "datetime"
        
        names(adaps_data)[grep("GH_Inst_cd", names(adaps_data))] <- "p00065_cd"
        names(adaps_data)[grep("GH_Inst", names(adaps_data))] <- "p00065"
        
        names(adaps_data)[grep("Flow_Inst_cd", names(adaps_data))] <- "p00060_cd"
        names(adaps_data)[grep("Flow_Inst", names(adaps_data))] <- "p00060"
        
        names(adaps_data)[grep("Count_Inst_cd", names(adaps_data))] <- "p99234_cd"
        names(adaps_data)[grep("Count_Inst", names(adaps_data))] <- "p99234"
        
        names(adaps_data)[grep("Precip_Inst_cd", names(adaps_data))] <- "p00045_cd"
        names(adaps_data)[grep("Precip", names(adaps_data))] <- "p00045"

        adaps_data <- adaps_data[, !(names(adaps_data) %in% c("p00045_cd", "p99234_cd",
                                                            "p00060_cd", "p00065_cd"))] 
        
        if(length(unique(c(siteNo, precipSite))) > 1){
          # if we add dplyr/tidyr we could pivot longer,
          # remove na's
          # pivot back wider
          adaps_1 <- adaps_data[adaps_data$site_no == siteNo, names(adaps_data)[!names(adaps_data) %in% c("p00045")]]
          adaps_2 <- adaps_data[adaps_data$site_no == precipSite, c("datetime", "p00045")]

          adaps_data <- merge(adaps_1, adaps_2,
                              by = "datetime", all = TRUE)[, union(names(adaps_1),
                                                                   names(adaps_2))]
          adaps_data <- adaps_data[!is.na(adaps_data$site_no), ] # this would be when there's precip with the non-precip site
        }
        
        if("p99234" %in% names(adaps_data)){
          # Should it be:
          # adaps_data <- adaps_data[adaps_data$p99234 > 900, ]
          adaps_data$p99234[adaps_data$p99234 < 900] <- NA
        }
        
        if("p00045" %in% names(adaps_data)){
          no_na_rain <- adaps_data$p00045
          no_na_rain[is.na(no_na_rain)] <- 0 
          adaps_data$cum_00045 <- cumsum(no_na_rain)
        }
        # Just to be sure:
        adaps_data$p00060 <- as.numeric(adaps_data$p00060)
        adaps_data$p00065 <- as.numeric(adaps_data$p00065)
        
        return(adaps_data)
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