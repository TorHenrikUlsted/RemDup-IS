server <- function(input, output, session) {
  message("UI has been generated")
  message("Initiating server")
  
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
  message("Server initiated")
}