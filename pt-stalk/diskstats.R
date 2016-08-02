library(ggplot2)

ptstalk.diskstats.graphs <- function(sourcedir, targetdir) 
{
	cnames = c("Device", "ReadsCompletedSuccessfully", "ReadsMerged", "SectorsRead", "TimeSpentReadingMS", "WritesCompleted", "WritesMerged", "SectorsWritten", "TimeSpentWritingMS", "IOsInProgress", "TimeSpentDoingIOs", "WeightedTimeSpentDoingIOs", "TS")
	
	rt <- NULL
	for (i in list.files(sourcedir,"diskstats", full.names = TRUE)) 
	{ 
		rt <- rbind(rt, read.table(i,fill=TRUE)) 
	}
	
	if (is.null(rt))
	{
		return()
	}
	
	rt$TS <- NA
	cTS <- NA
	for (i in 1:length(rt[[1]])) 
	{ 
		if (rt[[1]][i] == "TS") 
		{
			cTS <- paste(rt[[3]][i], rt[[4]][i])
		} else { 
			rt[["TS"]][i] <- cTS
		}
	}
	
	data <- subset(rt, V1 != "TS")
	data <- data[, !(names(data) %in% c("V1", "V2"))]
	colnames(data) <- cnames
	
	graphsdir <- ifelse(!is.na(targetdir), paste(targetdir, "/graphs", sep = ""), paste(sourcedir, "/graphs", sep = ""))
	#print(graphsdir)
	dir.create(file.path(graphsdir), showWarnings = FALSE)
	
	for (j in cnames[cnames != "Device" & cnames != "TS"]) 
	{
		mp <- ggplot(data, aes_string(x="TS",y=j,color="Device")) + geom_point()
		ggsave(paste(basename(sourcedir), "-diskstats-", j, ".png", sep = ""), plot = mp, path = graphsdir)
	}
}
