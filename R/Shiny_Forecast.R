library(shiny)

# Set working directory
setwd("./vignettes/")

# Load the file paths
file_paths <- list.files(path = "../data/Current_Output/", full.names = TRUE, pattern = "\\.jpg$")
file_dates <- as.POSIXct(strptime(basename(file_paths), "%Y-%m-%d_%H:%M:%S"), tz = "UTC")
names(file_paths) <- file_dates

# Define the UI
ui <- fluidPage(
  titlePanel("Image Viewer"),
  sliderInput("timeSlider", "Select Time:",
              min = min(file_dates),
              max = max(file_dates),
              value = min(file_dates),
              step = difftime(max(file_dates), min(file_dates)) / (length(file_dates) - 1),
              timeFormat="%Y-%m-%d %H:%M:%S"),
  imageOutput("image") # Image display area
)

# Define the server logic
server <- function(input, output, session) {
  output$image <- renderImage({
    selected_time <- input$timeSlider
    formatted_time <- format(selected_time, "%Y-%m-%d_%H:%M:%S")
    selected_file <- paste0("../data/Current_Output/", formatted_time, ".jpg")

    # Debugging information
    cat("Selected time:", selected_time, "\n")
    cat("Formatted time:", formatted_time, "\n")
    cat("Selected file:", selected_file, "\n")

    # Return the image info
    list(src = selected_file,
         contentType = 'image/jpeg',
         alt = "This is an image",
         width = "1800px",  # Set width
         height = "1000px"  # Set height
    )
  }, deleteFile = FALSE)



}



# Run the app
shinyApp(ui = ui, server = server)
