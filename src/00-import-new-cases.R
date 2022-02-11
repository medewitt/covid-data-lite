library(data.table)
library(dplyr)

# retrieve old data -------------------------------------------------------

current_data <- data.table::fread(here::here("data", "timeseries", "nc-cases-county.csv"))
#current_data <- current_data[county=="Guilford"]
current_data[,date:=as.Date(date)]

if(max(current_data$date) < Sys.Date()){



# retrieve new data -------------------------------------------------------

current_time <- format(Sys.time(), "%Y%m%d%H%M")
out <- jsonlite::fromJSON(readLines("https://services.arcgis.com/iFBq2AW9XO0jYYF7/arcgis/rest/services/NCCovid19/FeatureServer/0/query?where=0%3D0&outFields=%2A&f=json"))

attribute_out <- out$features$attributes

setDT(attribute_out)


# clean new data ----------------------------------------------------------

attribute_out[, update_date := as.POSIXct(current_time, format = "%Y%m%d%H%M")]

attribute_out[ ,date:= lubridate::date(update_date)]

dat_state <- copy(attribute_out[ , c("date", "Hosp")])

dat_raw <- attribute_out[ , c("date", "County", "Total", "Deaths", "PctPos")]

dat_raw[,PctPos:=as.numeric(PctPos)/100]

dat_raw <- dat_raw[,County:= stringr::str_remove(string = County, "County")]

dat_raw <- dat_raw[,County := stringr::str_trim(County)]

names(dat_raw) <- c("date", "county", "cases_confirmed_cum", "deaths_confirmed_cum", "pct_pos")

dat_raw$state <- "North Carolina"


# combine data and calculate differences ----------------------------------

dat_combined <- rbindlist(list(current_data, dat_raw), use.names = TRUE, fill = TRUE)

setorderv(dat_combined, cols = c("county", "date"))

dat_combined[,cases_daily:=fifelse(is.na(cases_daily),
                                  cases_confirmed_cum - lag(cases_confirmed_cum,1, default = 0), cases_daily), by = "county"]

dat_combined[,deaths_daily:=fifelse(is.na(deaths_daily),
                                    deaths_confirmed_cum - lag(deaths_confirmed_cum,1, default = 0), deaths_daily), by = "county"]

dat_combined[,cases_daily := fifelse(cases_daily <0 , 0, cases_daily)]
dat_combined[,deaths_daily := fifelse(deaths_daily <0 , 0, deaths_daily)]


# write out if new --------------------------------------------------------

if(sum(dat_combined[date==max(date)]$cases_daily)>1){
  data.table::fwrite(dat_combined, here::here("data", "timeseries", "nc-cases-county.csv"))
}
}
