library(SampleSplitting)
library(dataRetrieval)

#EDIT to include the name of the new storm folder
# setwd("//Sunset/data s archives/HNS_Archive/Water_Quality/GLRI_Edge_of_Field/RStudio Files")

# enter NWIS station id for gaging station
siteNo <- "411229084541102"
# enter date to begin pulling data (rounded to the day)
StartDt <- '2015-10-28'
# enter date to stop pulling data (rounded to the day)
EndDt <- '2015-10-28'
# enter NWIS station id for precipitation gaging station, may or may not be identical to "siteNo"
precipSite <- "411228084541701"
#tzCode <- "America/New_York"

# enter path and name of data file if data is not web-available - will need to be output to RDB in UTC time
#dataFile <- "//Sunset/data s archives/HNS_Archive/Water_Quality/GLRI_Edge_of_Field/RStudio Files/TL2.RDB"

# Run ONLY 1 of these options, depending on whether you are pulling data from the web, or providing a file
# Retrieve data from NWISWeb (if available)
adaps_data_all <- getADAPSData(siteNo,StartDt,EndDt,precipSite)
# or use file names to pull data in from files exported by ADAPS
#adaps_data_all <- getADAPSData(siteNo,StartDt,EndDt,precipSite,dataFile)

# save merged data for station/storm event, saved as file, eg 434425090462401data.txt 
adaps_data_allLocal <- adaps_data_all
adaps_data_allLocal$datetime <- adaps_data_allLocal$datetime-(5*60*60)
mergedDataTable(siteNo,StartDt,EndDt,adaps_data_allLocal)

# Generate interactive googleVis plot
hydrographPlot <- hydrographInteractive(adaps_data_allLocal)
plot(hydrographPlot)

# Generate pdf of hydrograph to save, saved as file, eg 434425090462401hydrograph.pdf 
# adjust dateInt as desired to vary length of time (in hours) between x-axis tick marks
hydrographPDF(adaps_data_allLocal,siteNo,dateInt=8)

# IF you have un-sampled storms, you may enter their StormStart and StormEnd values, as well as StormNames in 
# the appropriate list. Leave them out of the maxBottleVol, maxSampVol and subNum lists
# times should be in local/tz used in NWIS (not UTC)
# enter the name of the storm(s) (for plot title)
StormName <- c("411229084541102October28")
# enter Storm Start date(s)
# MUST be in the format YYYY-MM-DD HH:24
StormStart <- c("2015-10-28 01:15")
# enter Storm End date(s) 
# MUST be in the format YYYY-MM-DD HH:24
StormEnd <- c("2015-10-28 14:45")
# enter the maximum possible volume for one sample bottle
maxBottleVol <- c(800)
# enter the maximum possible volume for one full storm sample
maxSampVol <- c(3900)
# enter number for 1st bottle of each storm, if a number other than 1 is desired
subNum <- c(1001)

# generate bottle volume table(s) for lab for each storm
# source("//Sunset/data s archives/HNS_Archive/Water_Quality/GLRI_Edge_of_Field/RStudio Files/labDataOutMI.R")
tableOut <- labDataOutMI(adaps_data_all,StormStart,StormEnd,StormName,maxBottleVol,maxSampVol,subNum=subNum)
# look at table(s) generated for lab sample instructions for storm event(s). determine if changes are needed
for (i in 1:length(StormStart)){
  print(tableOut[[i]])
}
#Output csv file of all intermediate volumes used for calculations
intermediateVolTable(siteNo,StormStart,StormEnd,tableOut)

#######################################################################################################
# OPTIONAL if sample(s) need to be removed, enter their datetime and a comment and re-create tableOut
# MUST be in the format YYYY-MM-DD HH:24
removeDate <- c("")
removeComment <- c("")
tableOut <- labDataOutMI(adaps_data_all,StormStart,StormEnd,StormName,maxBottleVol,maxSampVol,removeDate=removeDate,subNum=subNum)
for (i in 1:length(StormStart)){
  print(tableOut[[i]])
}
intermediateVolTable(siteNo,StormStart,StormEnd,tableOut)
#######################################################################################################

#Once you are satisfied with the table output
#enter date(s) when samples were picked up 
bottlePickup <- c("Bottles 1001 through 1007 picked up 2015-10-29") 
# generate text file with storm event sample bottle volme table(s)
stormEventsTable(StormName,StormStart,StormEnd,tableOut,maxBottleVol,bottlePickup)

# generate simple table for lab
source("//Sunset/data s archives/HNS_Archive/Water_Quality/GLRI_Edge_of_Field/RStudio Files/labVolumesTableMI.R")
labVolumesTableMI(StormName,StormStart,StormEnd,tableOut,bottlePickup)
