#' Function to return data availability, internal or public, from NWISWeb
#' 
#' This function accepts an NWIS gage site id
#' 
#' @param siteNo NWIS gaging station id
#' @return SiteFile data frame of data available for a given site from NWISWeb
#' @export
#' @examples
#' \dontrun{
#' siteNo <- "441520088045002"
#' StartDt <- '2014-03-10'
#' EndDt <- '2014-03-17'
#' paramAvailability(siteNo)
#' }
paramAvailability <- function (siteNo) {
  dataRetrieval::setAccess("internal")
  SiteFile <- dataRetrieval::whatNWISdata(siteNumber = siteNo)
  
  SiteFile <- with(SiteFile, data.frame(parameter_cd = parm_cd, 
                                          statCd = stat_cd, startDate = begin_date, endDate = end_date, 
                                          count = count_nu, service = data_type_cd, access = 3, stringsAsFactors = FALSE))
  SiteFile <- unique(SiteFile)

  pCodes <- unique(SiteFile$parameter_cd)
  pcodeINFO <- dataRetrieval::readNWISpCode(pCodes)
  SiteFile <- merge(SiteFile, pcodeINFO, by = "parameter_cd")
  return(SiteFile)
}