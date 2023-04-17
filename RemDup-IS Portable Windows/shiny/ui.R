#  ____________________________________________________________________________
# |                                                                            |                                                                         
# |                     Shiny App for initial screening                        |
# |____________________________________________________________________________|
message("Generating UI")
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