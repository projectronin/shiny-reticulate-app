# Import R packages needed for the app here:
library(shiny)
library(DT)
library(RColorBrewer)
library(dplyr)
library(reticulate)

# Begin app server
shinyServer(function(input, output) {
  
  plot_cols <- brewer.pal(11, 'Spectral')
  
  # Import python functions to R
  source_python('python_functions.py')
  
  df <- readRDS('/share/mda_trial_PA19_0095/data/standardized/dat_notes_deltalake_current_pts.RDS') %>%
    filter(patient_letter=='AA') %>%
    filter(encounter_date_local_tz=='2020-12-01')
  print(df %>%
          select(patient_id, content_html,content_text,encounter_date_local_tz) %>%
          py$predict_ae())
  
  # Generate the requested distribution
  d <- reactive({
    dist <- switch(input$dist,
                   norm = rnorm,
                   unif = runif,
                   lnorm = rlnorm,
                   exp = rexp,
                   rnorm)
    
    return(dist(input$n))
  })
  
  # Generate a plot of the data
  output$plot <- renderPlot({
    dist <- input$dist
    n <- input$n
    
    return(hist(d(),
                main = paste0('Distribution plot: ', dist, '(n = ', n, ')'),
                xlab = '',
                col = plot_cols))
  })
  
  # Test that the Python functions have been imported
  output$message <- renderText({
    return(test_string_function(input$str))
  })
  
  # Test that numpy function can be used
  output$xy <- renderText({
    z = test_numpy_function(input$x, input$y)
    return(paste0('x + y = ', z))
  })
  
  # Display info about the system running the code
  output$sysinfo <- DT::renderDataTable({
    s = Sys.info()
    df = data.frame(Info_Field = names(s),
                    Current_System_Setting = as.character(s))
    return(datatable(df, rownames = F, selection = 'none',
                     style = 'bootstrap', filter = 'none', options = list(dom = 't')))
  })
  
  # Display system path to python
  output$which_python <- renderText({
    paste0('which python: ', Sys.which('python'))
  })
  
  # Display Python version
  output$python_version <- renderText({
    rr = reticulate::py_discover_config(use_environment = 'python35_env')
    paste0('Python version: ', rr$version)
  })
  
  # Display RETICULATE_PYTHON
  output$ret_env_var <- renderText({
    paste0('RETICULATE_PYTHON: ', Sys.getenv('RETICULATE_PYTHON'))
  })
  
  # Display virtualenv root
  output$venv_root <- renderText({
    paste0('virtualenv root: ', reticulate::virtualenv_root())
  })
  
})