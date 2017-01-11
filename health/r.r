wd <- "~/Desktop/d3/health"
setwd(wd)
getwd()

library(googleVis)
library(reshape2)

data<-read.csv("data.csv")
head(data)

### For Healthcare Cost Per Capita
d1 <- data[which(data$MEASURE=="VRPPPR"), ]
d1 <- d1[which(d1$Provider=="All providers" & d1$HF=="HFTOT" & d1$HC=="HCTOT"), ]

subvars3 <- c(9, 12, 19)
fdataPC <- d1[subvars3]

fdataPC1 <- dcast(fdataPC, Year~LOCATION, value.var="Value")

names(fdataPC1)[1] <- "date"

subvars4 <- c(1,2,4, 5, 7, 12, 13)
fd1 <- fdataPC1[subvars4]

write.table(fd1, file='percapita2.tsv', quote=FALSE, sep='\t', row.names=FALSE)


### For Healtcare Cost as a Percent of GDP
data1 <- data[which(data$Measure=="Share of gross domestic product"), ]
data2 <- data1[which(data1$Provider=="All providers"), ]
data3 <- data2[which(data2$Financing.scheme=="All financing schemes"), ]
data4 <- data3[which(data3$HC=="HCTOT"), ]

subvars1 <- c(9, 12, 19)
fdata<- data4[subvars1]

fdata1 <- dcast(fdata, Year~LOCATION, value.var="Value")

fdataUS<- fdata[which(fdata$LOCATION=="USA"), ]

subvars2 <- c(2,3)
fdataUS1 <- fdataUS[subvars2]

write.table(data1, file='health1.tsv', quote=FALSE, sep='\t', row.names=FALSE)


write.table(fdata1, file='health.tsv', quote=FALSE, sep='\t', row.names=FALSE)

write.csv(fdataUS1, file="us.csv", row.names=FALSE)
write.csv(fdata1, file="health.csv", row.names=FALSE)


Table <- gvisTable(d1)
plot(Table)