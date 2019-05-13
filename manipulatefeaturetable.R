# Read the inital feature table in
feature_table <- read.table("metaxa-feature-table.tsv",
							header = TRUE,
                            sep = "\t",
                            quote = "",
                            strip.white = TRUE,
							check.names = FALSE)

# Get the dimensions of the table
numSamples <- ncol(feature_table) - 1
numFeatures <- nrow(feature_table)

# Rearrange taxonomy so biom and QIIME like it
feature_table$taxonomy <- feature_table$Taxa
feature_table$Taxa <- NULL

# Add unique SampleIds for QIIME to work with
ids <- vector(length = numFeatures)
for (i in 1:numFeatures){
  # ARCC won't let us install packages, so we have to deal
  # with generating UUIDs ourselves using the code from:
  # https://stackoverflow.com/a/10493590/3922521
  baseuuid <- paste(sample(c(letters[1:6],0:9),30,replace=TRUE),collapse="")
  ids[i] <- paste(
    substr(baseuuid,1,8),
    "-",
    substr(baseuuid,9,12),
    "-",
    "4",
    substr(baseuuid,13,15),
    "-",
    sample(c("8","9","a","b"),1),
    substr(baseuuid,16,18),
    "-",
    substr(baseuuid,19,30),
    sep="",
    collapse=""
  )
}
feature_table$'#SampleId' <- ids
feature_table <- feature_table[c(numSamples+2, 1:(numSamples+1))]

# Write the file out
write.table(feature_table,
            file="feature-table.tsv",
            sep = "\t",
            quote = FALSE,
            row.names = FALSE)