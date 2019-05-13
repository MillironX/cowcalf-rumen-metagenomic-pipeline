metadata <- read.delim("metadata.tsv", header=FALSE)
metadata_columns <- head(metadata, 2)
metadata_columns <- as.data.frame(t(metadata_columns))
colnames(metadata_columns) <- c("Name", "DataType")
numcols <- subset(metadata_columns, DataType == "numeric")[,1]
catcols <- subset(metadata_columns, DataType == "categorical")[,1]
write.table(numcols,"numcols.txt",row.names = FALSE, col.names = FALSE, quote = FALSE)
write.table(catcols,"catcols.txt",row.names = FALSE, col.names = FALSE, quote = FALSE)