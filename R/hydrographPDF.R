#' Function to generate and save pdf version of the hydrograph plot 
#' 
#' This function accepts a merged data frame of ADAPS data for a site/storm event
#' 
#' @param adaps_data_all data frame containing merged ADAPS data for the requested storm event
#' @param siteNo string containing USGS gage number
#' @param dateInt number containing number of hours difference between x-axis tick marks
#' @export
hydrographPDF <- function(adaps_data_all,siteNo,dateInt) {
  adaps_data_samples <- adaps_data_all[which(adaps_data_all$p99234>0),c("datetime","p00060")]
  adaps_data_plot <- adaps_data_all[,c("datetime","cum_00045","p00065","p00060")]
  plot_00045 <- adaps_data_plot[which(!is.na(adaps_data_plot$cum_00045)),]
  plot_00060 <- adaps_data_plot[which(!is.na(adaps_data_plot$p00060)),]
  plot_00065 <- adaps_data_plot[which(!is.na(adaps_data_plot$p00065)),]
  plot_samp <- adaps_data_samples[which(!is.na(adaps_data_samples$p00060)),]
  startDt <- strftime(min(adaps_data_plot$datetime),format="%Y.%m.%d", tz=tzCode)
  endDt <- strftime(max(adaps_data_plot$datetime), format="%Y.%m.%d", tz=tzCode)
  ytop <- ifelse(max(plot_00045$cum_00045)>max(plot_00065$p00065),max(plot_00045$cum_00045),max(plot_00065$p00065))
  pdf(paste(siteNo,".",startDt,".",endDt,"hydrograph.pdf",sep=""),width=10,height=8)
  par(mar=c(8,4,5,4),xpd=T)
  plot(plot_00065$datetime,plot_00065$p00065,xaxt="n",xlab="",ylim=c(0,ytop),ylab="Rain, Stage",col="red",type="l",main=paste(siteNo,startDt,"-",endDt,sep=" "))
  lines(plot_00045$datetime,plot_00045$cum_00045,xlab="",ylab="",col="blue",type="l")
  a<-seq(min(adaps_data_plot$datetime),max(adaps_data_plot$datetime),dateInt*3600)
  axis.POSIXct(1,at=a,format="%m/%d %H:%M",las=2)
  mtext("Datetime",side=1,line=6)
  par(new=T)
  plot(plot_00060$datetime,plot_00060$p00060,axes=F,xlab="",ylab="",col="green",type="l")
  points(plot_samp$datetime,plot_samp$p00060,xlab="",ylab="",col="purple",pch="o")
  axis(side=4)
  mtext("Discharge",side=4,line=2)
  legend("topleft",c("ADAPS Corrected Q","ADAPS Corrected Stage","Storm Rain","Samples"),lty=c(1,1,1,NA),lwd=c(2.5,2.5,2.5),pch=c(NA,NA,NA,1),col=c("green","red","blue","purple"))
  dev.off()
}