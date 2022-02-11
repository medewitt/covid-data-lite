library(data.table)

initial_data <- data.table::fread(here::here("data", "timeseries", "nc-cases-county-raw.csv"))

initial_data[,date:=as.Date(date)]

corrections <- data.table::fread(here::here("data-raw", "cumulative-corrections.csv"))

setorderv(initial_data, c("county", "date"))
setorderv(corrections, "county")

corrections[,deaths_daily:= ifelse(is.na(deaths_daily),0,deaths_daily)]
initial_data[,deaths_confirmed_cum:=cumsum(deaths_daily), by = "county"]
corrections[,correct_death:= ifelse(is.na(correct_death),0,correct_death)]

# apply correction over 30 days ----------------------------------------

combined_to_correct <- merge(initial_data, corrections, by = "county", all.x = TRUE)

smooth_time <- 14

correction_period <- seq.Date(as.Date("2021-01-01"), length.out = smooth_time, by = "day")

combined_to_correct[date %in% correction_period, cases_daily := round(cases_daily + correction/smooth_time)]

combined_to_correct[date %in% correction_period, deaths_daily := round(deaths_daily + correct_death/smooth_time)]

combined_to_correct[order(date),cases_confirmed_cum := cumsum(cases_daily), by = "county"]
combined_to_correct[order(date),deaths_confirmed_cum := cumsum(deaths_daily), by = "county"]
combined_to_correct[county=="Alamance"]->inspection
combined_to_correct$correction <- NULL

combined_to_correct$correct_death <- NULL

fwrite(combined_to_correct, here::here("data", "timeseries","nc-cases-county.csv"))
