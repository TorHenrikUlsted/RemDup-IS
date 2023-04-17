#  ____________________________________________________________________________
# |                                                                            |                                                                         
# |                           Remove Duplications                              |
# |____________________________________________________________________________|

##README
#This code only works for ProQuest, Web of science and Scopus.
# No, you do not need all of them, but at least two, or else there would be no point to look for duplicates in the first place.
# If you want more you could implement them yourself or ask me to do so. It is not a complicated process.

# In order for this to work you need to undergo a few steps.
# 1. Web of Science: 
#   - Export references as excel file, add it to the resources folder and rename it to "wos". Then convert it to CSV.
# 2. Scopus:
#   - Export references as csv and check "Citation information" and "Abstract & keywords", this marks all of it, that is good. Then add to resources folder and rename to "scopus".
# 3. ProQuest:
#   - Export references as excel, add to resources folder and rename to "proQuest". Then open the file in excel and save as CSV.

message("Starting removal protocol")
message("reading csv files")
if(!require(dplyr)) {
  install.packages("dplyr")
  library(dplyr)
}
##Define variables
#You have to rename the files in your folder to this:
files <- c("proQuest", "wos", "scopus")
df_list <- list()

for (file in files) {
  path <- paste0("resources/", file, ".csv")
  if (file.exists(path)) {
    df_list[[file]] <- read.csv(path)
  } else {
    cat(file, "does not exist, I will ignore the object and continue\n","If you are expecting it to be there, check the spelling and if it is in the right folder\n")
  }
}

df_in_need_of_link = c("proQuest", "scopus")
source_names = c(proQuest = "ProQuest", wos = "Web of Science", scopus = "Scopus")
columnNames = c("Title", "Authors", "Year", "Type", "Abstract", "Keywords", "Link", "Source")

message("Renaming columns")
#Handle proQuest
if ("proQuest" %in% names(df_list)) {
  df_list$proQuest = df_list$proQuest %>% 
    select(Title, Authors, year, documentType, Abstract, identifierKeywords, digitalObjectIdentifier)
} else { cat("ProQuest is not a part of the list") }

#Handle wos
if ("wos" %in% names(df_list)) {
  df_list$wos = df_list$wos %>% 
    select(Article.Title, Authors, Publication.Year, Document.Type, Abstract, Keywords.Plus, DOI.Link)
} else { cat("Web of Science is not in the list") }

#Handle scopus
if ("scopus" %in% names(df_list)) {
  df_list$scopus = df_list$scopus %>% 
    select(Title, Authors, Year, Document.Type, Abstract, Author.Keywords, DOI, Source)
} else { cat("Scopus is not in the list") }

for (i in seq_along(df_list)) {
  df_list[[i]]$Source <- source_names[names(df_list)[i]]
  colnames(df_list[[i]]) <- columnNames
}
message("Fixing links")
#make the DOI an actual link
for (item in df_in_need_of_link) {
  if (item %in% names(df_list)) {
    df_list[[item]]$Link = paste0("http://dx.doi.org/", df_list[[item]]$Link)
  }
}
message("Merging dataframes")
#Merge all data frames into a single data frame
merged_df = Reduce(function(x, y) merge(x, y, all=T), df_list)

message("Removing duplications")
##Remove duplicates
if(!require(stringdist)) {
  install.packages("stringdist")
  library(stringdist)
}

#Use the stringdist library to check for similarities between 0 and threshold, which is now set to 0.2 or 80%
#Title and year will be enough for the most part. The issue by including Authors is that the sources use different separators.
crit = paste(merged_df$Title, merged_df$Year)
crit <- as.character(crit)
dist_matrix = as.matrix(stringdistmatrix(crit, method = "jw"))
threshold = 0.2
to_remove = which(apply(dist_matrix, 1, function(x) any(x > 0 & x <= threshold) ))
#Remove the duplicates
rmDup_df = merged_df[-to_remove, ]
#Add the duplicates into a new dataframe
duplicates_df = merged_df[to_remove, ]
##Update duplicates list
duplicates_df = rmDup_df[duplicated(rmDup_df[,c("Title", "Year")]), ]
#For some reason it won't remove identical ones, but only similar ones above 0, which is 100% identical. Thus This level as well.
rmDup_df = rmDup_df[!duplicated(rmDup_df[,c("Title", "Year")]), ]

#Number of papers left from each Source
table(rmDup_df$Source)

#Make a sample of all your data left
sample = rmDup_df

message("Sourcing columns")
titles <- sample[, 1]
authors <- sample[, 2]
years <- sample[, 3]
types <- sample[, 4]
abstracts <- sample[, 5]
keywords <- sample[, 6]
links <- sample[,7]
sources <- sample[,8]

# Initialize global variables for excluded and included articles
excludedArticles <<- reactiveVal(data.frame())
includedArticles <<- reactiveVal(data.frame())

message("Finished removing duplications")
message("CTRL + click on the link below")
