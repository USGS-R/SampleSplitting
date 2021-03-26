
library(SampleSplitting)
library(dataRetrieval)
# enter NWIS station id for gaging station
siteNo <- "424314090240601"
# enter date to begin pulling data (rounded to the day)
StartDt <- '2008-05-30'
# enter date to stop pulling data (rounded to the day)
EndDt <- '2008-06-15'
# enter NWIS station id for precipitation gaging station, may or may not be identical to "siteNo"
precipSite <- "434425090462401"
# enter a timezone to return data in for data retrieved from the web
# choose from America/Chicago, America/New_York, America/Denver, America/Los_Angeles, America/Phoenix, America/Anchorage, America/Honolulu, America/Jamaica, America/Metlakatla, America/Managua
tzCode <- "America/Chicago"

# enter path and name of data file if data is not web-available
dataFile <- "M:/NonPoint Evaluation/GLRI Edge-of-field/Splitting Record Conversion to R/PLAT2TESTJLT.RDB"

# Run ONLY 1 of these options, depending on whether you are pulling data from the web, or providing a file
# Retrieve data from NWISWeb (if available)
adaps_data_all <- getADAPSData(siteNo,StartDt,EndDt,precipSite,tzCode=tzCode)
# or use file names to pull data in from files exported by ADAPS
adaps_data_all <- getADAPSData(siteNo,StartDt,EndDt,precipSite,dataFile)

# save merged data for station/storm event, saved as file, eg 434425090462401data.txt 
mergedDataTable(siteNo,StartDt,EndDt,adaps_data_all)

# Generate interactive googleVis plot
hydrographPlot <- hydrographInteractive(adaps_data_all)
plot(hydrographPlot)

# Generate pdf of hydrograph to save, saved as file, eg 434425090462401hydrograph.pdf 
# adjust dateInt as desired to vary length of time (in hours) between x-axis tick marks
hydrographPDF(adaps_data_all,siteNo,dateInt=8)

# IF you have un-sampled storms, you may enter their StormStart and StormEnd values, as well as StormNames in 
# the appropriate list. Leave them out of the maxBottleVol, maxSampVol and subNum lists
# enter the name of the storm(s) (for plot title)
# MUST be in the format Name-Number
StormName <- c("S2-066","S2-066A","S2-067","S2-068","S2-069","S2-070","S2-071","S2-072","S2-073","S2-074","S2-075")
# enter Storm Start date(s)
# MUST be in the format YYYY-MM-DD HH:24
StormStart <- c("2008-05-30 02:51","2008-06-01 02:30","2008-06-05 04:39","2008-06-06 04:22","2008-06-07 22:52",
                "2008-06-08 08:41","2008-06-08 19:03","2008-06-12 09:03","2008-06-12 21:40","2008-06-14 16:52",
                "2008-06-15 04:07")
# enter Storm End date(s) 
# MUST be in the format YYYY-MM-DD HH:24
StormEnd <- c("2008-05-30 08:49","2008-06-01 22:45","2008-06-05 07:21","2008-06-06 05:28","2008-06-08 01:14",
              "2008-06-08 11:39","2008-06-08 21:31","2008-06-12 10:22","2008-06-13 01:36","2008-06-14 18:05",
              "2008-06-15 09:22")
# enter the maximum possible volume for one sample bottle
maxBottleVol <- c(400,600,600,600,600,600,600,400,600,800)
# enter the maximum possible volume for one full storm sample
maxSampVol <- c(3900,3900,3900,3900,3900,3900,3900,3900,3900,3900)
# enter number for 1st bottle of each storm, if a number other than 1 is desired
subNum <- c(1,1,1,1,16,1,1,5,1,7)

# generate bottle volume table(s) for lab for each storm
tableOut <- labDataOut(adaps_data_all,StormStart,StormEnd,StormName,maxBottleVol,maxSampVol,subNum=subNum)
# look at table(s) generated for lab sample instructions for storm event(s). determine if changes are needed
for (i in 1:length(StormStart)){
  print(tableOut[[i]])
}
#Output csv file of all intermediate volumes used for calculations
intermediateVolTable(siteNo,StormStart,StormEnd,tableOut)

# OPTIONAL if sample(s) need to be removed, enter their datetime and a comment and re-create tableOut
# MUST be in the format YYYY-MM-DD HH:24
removeDate <- c("2008-05-30 07:44")
removeComment <- c("")
tableOut <- labDataOut(adaps_data_all,StormStart,StormEnd,StormName,maxBottleVol,maxSampVol,removeDate=removeDate,subNum=subNum)
for (i in 1:length(StormStart)){
  print(tableOut[[i]])
}
intermediateVolTable(siteNo,StormStart,StormEnd,tableOut)

#Once you are satisfied with the table output
#enter date(s) when samples were picked up 
bottlePickup <- c("Bottles S2-1 through S2-26 picked up 2008-05-30",
                  "Bottles S2-1 through S2-15 picked up 2008-06-05",
                  "Bottles S2-1 through S2-6 picked up 2008-06-06",
                  "Bottles S2-1 through S2-9 picked up 2008-06-07 and bottles S2-10 through S2-15 picked up 2008-06-08",
                  "Bottles S2-16 through S2-25 picked up 2008-06-09",
                  "Bottles S2-1 through S2-9 picked up 2008-06-10",
                  "Bottles S2-1 through S2-7 picked up 2008-06-12",
                  "Bottles S2-5 through S2-25 picked up 2008-06-13",
                  "Bottles S2-1 through S2-6 picked up 2008-06-14",
                  "Bottles S2-7 through S2-17 picked up 2008-06-15")

# generate text file with storm event sample bottle volume table(s)
stormEventsTable(StormName,StormStart,StormEnd,tableOut,maxBottleVol,bottlePickup)

# generate simple table for lab
labVolumesTable(StormName,StormStart,StormEnd,tableOut,bottlePickup)

