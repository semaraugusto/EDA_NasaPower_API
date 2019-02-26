`%!in%` <- function(x, table) {
  match(x, table, nomatch = 0L) == 0L
}

query_nasa_api <- function(min_x, min_y, max_x, max_y, startDate, endDate){
  url <- paste0('https://power.larc.nasa.gov/cgi-bin/v1/DataAccess.py?request=execute&identifier=Regional&parameters=ALLSKY_SFC_SW_DWN&startDate=', 
                startDate, '&endDate=', endDate, '&userCommunity=SSE&tempAverage=INTERANNUAL&outputList=CSV')
  mid_url <- paste0('&bbox=',min_y, ',', min_x, ',', max_y, ',', max_x)
  final_url <- '&user=anonymous'
  
  url <- paste0(url, mid_url, final_url)
  client <- crul::HttpClient$new(url)
  tryCatch({
    response <- client$get()
    txt <- jsonlite::fromJSON(response$parse("UTF-8"))
    raw_power_data <- file.path(tempdir(), "power_data_file")
  }, error = function(e) {
    e$message <- "Algo deu errado"
    e$call <- NULL
    stop(e)
  })
  
  if ("messages" %in% names(txt) & "outputs" %!in% names(txt)) {
    stop(
      call. = FALSE,
      unlist(txt$messages)
    )
  }
  
  curl::curl_download(txt$output$csv,
                      destfile = raw_power_data,
                      mode = "wb",
                      quiet = TRUE)
  
  skip_lines <- 10
  
  power_data <- readr::read_csv(raw_power_data,
                                col_types = readr::cols(),
                                na = "-99",
                                skip = skip_lines
  )
  # switch lon and lat (x, y) format
  power_data <- power_data[, c(2, 1, 3:ncol(power_data))]
  
  return(power_data)
}



# query_nasa_api <- function(min_x, min_y, max_x, max_y, startDate, endDate){
#   url <- paste0('https://power.larc.nasa.gov/cgi-bin/v1/DataAccess.py?request=execute&identifier=Regional&parameters=ALLSKY_SFC_SW_DWN&startDate=', 
#                 startDate, '&endDate=', endDate, '&userCommunity=SSE&tempAverage=INTERANNUAL&outputList=CSV')
#   mid_url <- paste0('&bbox=',min_y, ',', min_x, ',', max_y, ',', max_x)
#   final_url <- '&user=anonymous'
#   
#   url <- paste0(url, mid_url, final_url)
#   client <- crul::HttpClient$new(url)
#   tryCatch({
#     response <- client$get()
#     txt <- jsonlite::fromJSON(response$parse("UTF-8"))
#     raw_power_data <- file.path(tempdir(), "power_data_file")
#   }, error = function(e) {
#     e$message <- "Algo deu errado"
#     e$call <- NULL
#     stop(e)
#   })
#   
#   if ("messages" %in% names(txt) & "outputs" %!in% names(txt)) {
#     stop(
#       call. = FALSE,
#       unlist(txt$messages)
#     )
#   }
#   
#   curl::curl_download(txt$output$csv,
#                       destfile = raw_power_data,
#                       mode = "wb",
#                       quiet = TRUE)
#   
#   skip_lines <- 10
#   
#   power_data <- readr::read_csv(raw_power_data,
#                                 col_types = readr::cols(),
#                                 na = "-99",
#                                 skip = skip_lines
#   )
#   # switch lon and lat (x, y) format
#   power_data <- power_data[, c(2, 1, 3:ncol(power_data))]
#   
#   return(power_data)
# }
