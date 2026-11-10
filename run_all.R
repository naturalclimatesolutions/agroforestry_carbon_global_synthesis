# Run the full analysis pipeline (notebooks 01 -> 10) from a clean state.
#
# Usage, from the repository root:
#   source("run_all.R")                       # interactive session
#   Rscript run_all.R                         # command line
#   Rscript run_all.R --use-cache             # reuse cached RF/SHAP results in 09
#   Rscript run_all.R --from=05               # resume at the first notebook whose
#                                             # name starts with "06" (needs earlier
#                                             # intermediates in output/intermediate/)
#   Rscript run_all.R --skip=09               # skip notebooks whose names start with
#                                             # any of the given prefixes (comma-separated)
# Options can also be set via env vars RUN_ALL_USE_CACHE=true, RUN_ALL_FROM=05,
# RUN_ALL_SKIP=09.
#
# Each notebook is rendered in a fresh environment. HTML reports go to
# output/intermediate/html/ (gitignored). The run stops at the first error.

library(here)
library(rmarkdown)

args <- commandArgs(trailingOnly = TRUE)
use_cache_rf <- "--use-cache" %in% args || tolower(Sys.getenv("RUN_ALL_USE_CACHE")) == "true"
run_from <- sub("^--from=", "", grep("^--from=", args, value = TRUE))
if (length(run_from) == 0) run_from <- Sys.getenv("RUN_ALL_FROM")
run_skip <- sub("^--skip=", "", grep("^--skip=", args, value = TRUE))
if (length(run_skip) == 0) run_skip <- Sys.getenv("RUN_ALL_SKIP")
run_skip <- trimws(strsplit(run_skip, ",")[[1]])

nb_dir <- here("notebooks")
html_dir <- here("output", "intermediate", "html")
dir.create(html_dir, recursive = TRUE, showWarnings = FALSE)

steps <- list(
  list(nb = "01_summarize_covariates_by_plot"),
  list(nb = "02a_agc_by_plot_and_age"),
  list(nb = "02b_bgc_by_plot_and_age"),
  list(nb = "02c_soc_by_plot_and_age"),
  list(nb = "03a_join_c_stock_covariates", params = list(c_data_name = "agc")),
  list(nb = "03a_join_c_stock_covariates", params = list(c_data_name = "bgc")),
  list(nb = "03a_join_c_stock_covariates", params = list(c_data_name = "soc")),
  list(nb = "03b_join_c_change_covariates", params = list(c_data_name = "agc_change")),
  list(nb = "03b_join_c_change_covariates", params = list(c_data_name = "bgc_change")),
  list(nb = "03b_join_c_change_covariates", params = list(c_data_name = "soc_change")),
  list(nb = "04_drop_outliers"),
  list(nb = "05_bivariate_analysis"),
  list(nb = "06_predictor_summary_table"),
  list(nb = "07_chapman_richards_fits"),
  list(nb = "08_compare_to_ipcc"),
  list(nb = "09_random_forest", params = list(use_cache = use_cache_rf)),
  list(nb = "10_summary_stats_and_extra_figures")
)

run_step <- function(step) {
  input <- file.path(nb_dir, paste0(step$nb, ".Rmd"))
  suffix <- if (is.null(step$params$c_data_name)) "" else paste0("_", step$params$c_data_name)
  label <- paste0(step$nb, suffix)
  env <- new.env(parent = globalenv())

  message(sprintf("[%s] START %s", format(Sys.time(), "%H:%M:%S"), label))
  t0 <- Sys.time()
  render(
    input,
    output_file = paste0(label, ".html"),
    output_dir = html_dir,
    intermediates_dir = tempdir(),
    knit_root_dir = here(),
    params = step$params,
    envir = env,
    quiet = TRUE
  )
  mins <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
  message(sprintf("[%s] DONE  %s (%.1f min)", format(Sys.time(), "%H:%M:%S"), label, mins))
  data.frame(step = label, minutes = round(mins, 1))
}

if (nzchar(run_from)) {
  start <- which(startsWith(vapply(steps, `[[`, "", "nb"), run_from))[1]
  if (is.na(start)) stop("No notebook starts with '", run_from, "'")
  steps <- steps[start:length(steps)]
}

if (length(run_skip)) {
  skip <- vapply(steps, \(st) any(startsWith(st$nb, run_skip)), logical(1))
  message("Skipping: ", paste(unique(vapply(steps[skip], `[[`, "", "nb")), collapse = ", "))
  steps <- steps[!skip]
}

run_start <- Sys.time()
timings <- do.call(rbind, lapply(steps, run_step))
print(timings)
message(sprintf("Pipeline complete: %.1f min total", sum(timings$minutes)))

# Outputs not rewritten in this run (e.g. a file open in Excel that failed to
# save, or notebooks skipped / not re-run with --from)
out_files <- list.files(here("output", c("tables", "figures", "data")), full.names = TRUE)
out_files <- out_files[!startsWith(basename(out_files), "~$")]
stale <- out_files[file.mtime(out_files) < run_start]
if (length(stale)) message("Outputs NOT rewritten in this run:\n  ", paste(sub(paste0(here(), "/"), "", stale), collapse = "\n  "))
