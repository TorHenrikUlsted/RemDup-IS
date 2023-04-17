print("Initiating App protocol")

#Set R-Portable as R version
.libPaths("R-Portable")
message('library paths:\n', paste('... ', .libPaths(), sep='', collapse='\n'))

shiny::runApp('./shiny/')
