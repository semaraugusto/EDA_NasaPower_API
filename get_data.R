require(RMySQL)
require(nasapower)
library(rgdal)
source("query_nasa_api.R")

brazil <- readOGR("UFEBRASIL.shp", encoding = "UTF-8")

nx <- abs((brazil@bbox[1,1] - brazil@bbox[1,2]) %/% 4.5) 
ny <- abs((brazil@bbox[2,1] - brazil@bbox[2,2]) %/% 4.5)

min_x <- min(brazil@bbox[1,])
max_x <- min_x + 4.5

# Salva os dados do brasil inteiro
for(i in 1:nx) {
  min_y <- min(brazil@bbox[2,])
  max_y <- min_y + 4.5
  
  for(j in 1:ny) {
    if(i == 1 && j == 1) {
      df <- query_nasa_api(min_x, min_y, max_x, max_y, 1984, 2005)
      
    } else {
      aux <- query_nasa_api(min_x, min_y, max_x, max_y, 1984, 2005)
      df <- rbind(df, aux)
    }
    
    min_y <- max_y
    max_y <- max_y + 4.5
  }
  
  min_x <- max_x
  max_x <- max_x + 4.5
}

# Pre-processing
df$PARAMETER <- NULL

f <- data.frame(x = df$LON, y = df$LAT, id="A", stringsAsFactors = F)
coordinates(f) <- ~ x+y
proj4string(f) <- proj4string(brazil)
states <- over(f, brazil)
df$STATE <- states$nome

rm(f, states)

df <- df[complete.cases(df),]
write.csv(df, "radiacao_sql.csv", row.names = FALSE)

con <- dbConnect(dbDriver("MySQL"), user = "root", password = "root", dbname = "solarview", host="localhost")
dbWriteTable(con,"yourTableinMySQL", df, overwrite=TRUE)
dbDisconnect(con)

