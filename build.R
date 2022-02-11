src_files <-  fs::dir_ls(path = here::here("src"), glob = "*.R")

cmd <- glue::glue("Rscript --vanilla {src_files}")

for(i in seq_along(cmd)){
  system(cmd[i])
}
