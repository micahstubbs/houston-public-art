setwd("C:/Users/m/workspace/houston-public-art/")

file <- "all-coh-publicart-hackathon2015.csv"
source_data <- read.csv(file, header=TRUE, sep=",", quote = "\"", na.strings = "")

data <- source_data

# rename columns
names(data)[names(data)=="Accession.Number"] <- "accessionNumber"
names(data)[names(data)=="Temp.ID"] <- "tempID"
names(data)[names(data)=="Display.Title"] <- "displayTitle"
names(data)[names(data)=="Display.Artist"] <- "displayArtist"
names(data)[names(data)=="Creation.Date"] <- "creationDate"
names(data)[names(data)=="Media...Support"] <- "mediaAndSupport"
names(data)[names(data)=="Credit.Line"] <- "creditLine"
names(data)[names(data)=="Current.Location"] <- "currentLocationAddress"
names(data)[names(data)=="Specific.Location"] <- "specificLocation"
names(data)[names(data)=="Department"] <- "department"
names(data)[names(data)=="Council.District"] <- "councilDistrict"
          
library(dplyr)
data <- mutate(data,
       compositeID = paste0(accessionNumber,tempID)
       )
# remove the accessionNumber and tempID columns
data <- subset(data, select=-c(accessionNumber, tempID))

# retain only rows with values in all fields
data <- data[!is.na(data$displayTitle),]
data <- data[!is.na(data$displayArtist),]
data <- data[!is.na(data$creationDate),]
data <- data[!is.na(data$mediaAndSupport),]
data <- data[!is.na(data$creditLine),]
data <- data[!is.na(data$currentLocation),]
data <- data[!is.na(data$creationDate),]
data <- data[!is.na(data$specificLocation),]
data <- data[!is.na(data$department),]
data <- data[!is.na(data$councilDistrict),]
data <- data[!is.na(data$compositeID),]

# sort by creationDate
data <- arrange(data, creationDate)

# rename the creationDate column to the more accurate completionYear
names(data)[names(data)=="creationDate"] <- "completionYear"

# update some specific values in the completionYear column
data[17, 'completionYear'] <- "1966"
data[55, 'completionYear'] <- "1905"

# remove rows without specific year values for completionYear
data <- data[-c(56,57),]

library(httr)
library(rjson)

# get latitude and longitude values for the addresses in the currentLocationAddress column
request_data <- paste0("[",paste(paste0("\"",data$currentLocationAddress,"\""),collapse=","),"]")
url  <- "http://www.datasciencetoolkit.org/street2coordinates"
response <- POST(url,body=request_data)
json     <- fromJSON(content(response,type="text"))
geocode  <- do.call(rbind,lapply(json,
                                 function(x) c(long=x$longitude,lat=x$latitude)))

# merge the lat and long values into the data dataframe
data <- merge(data, geocode, by.x = c("currentLocationAddress"), by.y = c("row.names"))

# write out materials for manual parsing
materials <- unique(data$mediaAndSupport)
output_file <- "materials.csv"
write.csv(materials, output_file, row.names=FALSE, na="")

# read in list of unique materials with counts
file <- "materials-count.csv"
materials_count <- read.csv(file, header=TRUE, sep=",", quote = "\"", na.strings = "")

# merge the material counts into the data dataframe
data <- merge(data, materials_count, by = c("mediaAndSupport"))

# standardize a value for mediaAndSupport
data[23, 'mediaAndSupport'] <- "Painted Steel"

# write out data
output_file <- "houston-public-art-cleaned.csv"
write.csv(data, output_file, row.names=FALSE, na="")
