##README
# This code only works for ProQuest, Web of science and Scopus.
# You do not need all of them.
# If you want more you could implement them yourself or ask me to do so. It is not a complicated process.
# Now, if it works correctly, you should only need to change the files and do shift+ctrl/cmd+enter and it should work

# In order for this to work you need to undergo a few steps.
# 1. Web of Science: 
#   - Export references as excel file, IMPORTANT: download "full record", add it to the resources folder and rename it to "wos". Then convert it to CSV.
# 2. Scopus:
#   - Export references as csv and check "Citation information" and "Abstract & keywords", this marks all of it, that is good. Then add to resources folder and rename to "scopus".
# 3. ProQuest:
#   - Export references as excel, add to resources folder and rename to "proQuest". Then open the file in excel and save as CSV.

#  ____________________________________________________________________________
# |                                                                            |                                                                         
# |                           Remove Duplications                              |
# |____________________________________________________________________________|

#Load dplyr
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

#make the DOI an actual link
for (item in df_in_need_of_link) {
  if (item %in% names(df_list)) {
    df_list[[item]]$Link = paste0("https://dx.doi.org/", df_list[[item]]$Link)
  }
}

#Merge all data frames into a single data frame
merged_df = Reduce(function(x, y) merge(x, y, all=T), df_list)

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

#  ____________________________________________________________________________
# |                                                                            |                                                                         
# |                     Shiny App for initial screening                        |
# |____________________________________________________________________________|

#Here I want to add title and keywords, as well as backgorund color of which one you are at
if(!require(shiny)) {
  install.packages("shiny")
  library(shiny)
}

# Define the abstracts using column 5 of the sample table and links in 7
sample <- rmDup_df

titles <- sample[, 1]
authors <- sample[, 2]
years <- sample[, 3]
types <- sample[, 4]
abstracts <- sample[, 5]
keywords <- sample[, 6]
links <- sample[,7]
sources <- sample[,8]

ui <- fluidPage(
  # Add custom CSS to style the abstract and navigation numbers
  tags$head(
    includeCSS("www/main.css")
  ),
  
  div( id = "wrapper",
    #Add article title
    div( id = "title",
      h4("Title", 
      ),
      h3(
        style = "font-weight: bold;",
        uiOutput("current_title"),
      )
    ), #End title
    
    # Display the current abstract
    div(id = "abDiv",
      h4("Abstract", align = "center"),
      div(id = "abtext",
          align = "center",
          htmlOutput("current_abstract"),
      ),
    ), # end abstract
    
    #Add input field for search string
    div(id = "inputDiv",
      textInput("search_query", "Search String"),
    ), #end inputDiv
    
    #Display attributes
    div( id="attrib",
         uiOutput("current_type"),
         uiOutput("current_year"),
         uiOutput("current_authors"),
         uiOutput("current_keywords"),
         uiOutput("current_link"),
         
    ), #end attrib
    
    # Add buttons for navigation
    div(id="nav_buttons",
        align = "center",
        actionButton("include_button", label = "Include", icon("check") ),
        actionButton("exclude_button", label = "Exclude", icon("ban") ),
        span(HTML("&nbsp;&nbsp;&nbsp;")), # Add non-breaking spaces
        actionButton("prev_button", label = "Previous", icon("arrow-left") ),
        actionButton("next_button", label = "Next", icon("arrow-right") ),
        
        
    ), #end nav_buttons
  
    
    # Add buttons for adding rows to dataframes
    div(id="add_buttons",
        #align = "center",
        
    ), #end add_buttons
    
    # Add clickable numbers for navigation
    div(id = "navNumbersDiv",
        uiOutput("nav_numbers"),
    ), #end nav-numbers
    
    div(id = "excludedPile",
        h3("Excluded Pile", align = "center"),
        tableOutput("excluded_table")
    ), #end exludedPile
    
    div( id = "includedPile",
         h3("Included Pile", align = "center"),
         tableOutput("included_table"),
    ), #end includedPile
  ),
  
)

# Initialize global variables for excluded and included articles
excludedArticles <<- reactiveVal(data.frame())
includedArticles <<- reactiveVal(data.frame())

server <- function(input, output, session) {
  
  # Add a callback to be called when a user session ends
  session$onSessionEnded(function() {
    write.csv(isolate(excludedArticles()), "resources/excluded_articles.csv", row.names = FALSE)
    write.csv(isolate(includedArticles()), "resources/included_articles.csv", row.names = FALSE)
  })
    

  # Keep track of the current index
  current_index <- reactiveVal(1)
  
  # Define the output names and corresponding data
  outputs <- list(
    current_title = titles,
    current_authors = authors,
    current_year = years,
    current_type = types,
    current_abstract = abstracts,
    current_keywords = keywords,
    current_source = sources
  )
  
  # Generate the outputs using a loop
  for (name in names(outputs)) {
    local({
      # Get the output name and data
      output_name <- name
      data <- outputs[[name]]
      
      # Generate the output
      output[[output_name]] <- renderText({
        # Get the current value
        value <- data[current_index()]
        
        # Print the current value for debugging
        #print(paste(output_name, value))
        
        # Check if the value is NA
        if (is.na(value) || value == "") {
          # Return a string indicating that there is no data
          "No data"
        } else {
          # Return the value
          value
        }
      })
    })
  }
  
  
  # Generate the link output separately
  output$current_link <- renderUI({
    a(links[current_index()], href=links[current_index()])
  })
  
  
  # Reactive expression to modify the abstract text
  modified_abstract <- reactive({
    # Get the search query from the textInput
    search_query <- input$search_query
    
    # Check if the search query is empty
    if (search_query == "") {
      # If the search query is empty, return the original abstract text
      abstracts[current_index()]
    } else {
      # If the search query is not empty, modify the abstract text
      
      # Split the search query into phrases and individual words
      search_phrases <- strsplit(search_query, '"')[[1]]
      search_words <- c()
      for (i in seq_along(search_phrases)) {
        if (i %% 2 == 1) {
          search_words <- c(search_words, unlist(strsplit(search_phrases[i], " ")))
        } else {
          search_words <- c(search_words, search_phrases[i])
        }
      }
      
      # Trim any leading or trailing whitespace from each search word
      search_words <- trimws(search_words)
      # Remove any empty search words
      search_words <- search_words[search_words != ""]
      # Remove any parentheses from each search word
      search_words <- gsub("[()]", "", search_words)
      # Remove any boolean operators or proximity functions from the list of search words
      search_words <- search_words[!search_words %in% c("AND", "OR", "NOT", "NEAR", "PRE", "ANDNOT")]
      # Create a list to store the modified search words
      modified_search_words <- list()
      # Loop over each search word
      for (search_word in search_words) {
        # Check if the search word ends with an asterisk (*)
        if (endsWith(search_word, "*")) {
          # If it does, remove the asterisk and add a regular expression pattern that matches zero or more word characters
          modified_search_word <- paste0(substr(search_word, 1, nchar(search_word) - 1), "\\w*")
        } else {
          # If it doesn't, use the search word as-is
          modified_search_word <- search_word
        }
        # Add the modified search word to the list of modified search words
        modified_search_words[[length(modified_search_words) + 1]] <- modified_search_word
      }
      # Create a regular expression pattern that matches any of the modified search words
      pattern <- paste0("\\b(", paste(modified_search_words, collapse = "|"), ")\\b")
      # Get the current abstract text
      abstract_text <- abstracts[current_index()]
      # Use gsub to replace all instances of the modified search words with a highlighted version
      gsub(pattern, '<mark>\\1</mark>', abstract_text, ignore.case = TRUE)
    }
  })
  
  # Generate the current_abstract output using the modified_abstract reactive expression
  output$current_abstract <- renderUI({
    HTML(modified_abstract())
  })
  
  
  # Update the index when a button is clicked
  observeEvent(input$prev_button, {
    current_index(max(1, current_index() - 1))
  })
  observeEvent(input$next_button, {
    current_index(min(length(abstracts), current_index() + 1))
  })
  
  
  # Generate clickable numbers for navigation
  output$nav_numbers <- renderUI({
    lapply(seq_along(abstracts), function(i) {
      # Add the 'active' class to the current nav number
      class <- if (i == current_index()) "nav-number active" else "nav-number"
      
      actionLink(paste0("nav_", i), label = i, class = class)
    })
  })
  
  # Update the index when a number is clicked
  observe({
    lapply(seq_along(abstracts), function(i) {
      observeEvent(input[[paste0("nav_", i)]], {
        current_index(i)
      })
    })
  })
  

  # Initialize reactive values for excluded and included articles
  excludedArticles <- reactiveVal(data.frame())
  includedArticles <- reactiveVal(data.frame())
  
  observeEvent(input$exclude_button, {
    # Get the current row of data
    row <- sample[current_index(),]
    # Add the ID column to the row
    row$ID <- current_index()
    
    # Check if the current item is already in the excluded pile
    if (current_index() %in% excludedArticles()$ID) {
      # Remove the current item from the excluded pile
      excludedArticles(excludedArticles()[excludedArticles()$ID != current_index(), ])
    } else {
      # Add the current item to the excluded pile
      excludedArticles(rbind(excludedArticles(), row))
      
      # Remove the current item from the included pile (if it's there)
      includedArticles(includedArticles()[includedArticles()$ID != current_index(), ])
    }
  })
  observeEvent(input$include_button, {
    # Get the current row of data
    row <- sample[current_index(),]
    # Add the ID column to the row
    row$ID <- current_index()
    
    # Check if the current item is already in the included pile
    if (current_index() %in% includedArticles()$ID) {
      # Remove the current item from the included pile
      includedArticles(includedArticles()[includedArticles()$ID != current_index(), ])
    } else {
      # Add the current item to the included pile
      includedArticles(rbind(includedArticles(), row))
      
      # Remove the current item from the excluded pile (if it's there)
      excludedArticles(excludedArticles()[excludedArticles()$ID != current_index(), ])
    }
  })
  
  # Render tables for excluded and included articles
  output$excluded_table <- renderTable({ excludedArticles() })
  output$included_table <- renderTable({ includedArticles() })
  
}

shinyApp(ui = ui, server = server)

# Read data from CSV file into R
excluded_articles <- read.csv("resources/excluded_articles.csv")
included_articles <- read.csv("resources/included_articles.csv")

