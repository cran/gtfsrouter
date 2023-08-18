## ----DTthread, echo = FALSE---------------------------------------------------
# Necessary for CRAN to avoid CPU / elapsed time ratios being too high
data.table::setDTthreads (1)

## ----berlin_gtfs--------------------------------------------------------------
library (gtfsrouter)
berlin_gtfs_to_zip ()
f <- file.path (tempdir (), "vbb.zip")
gtfs <- extract_gtfs (f, quiet = TRUE)
gtfs <- gtfs_timetable (gtfs, day = 3)

## ----traveltimes--------------------------------------------------------------
from <- "Alexanderplatz"
start_time_limits <- c (12, 13) * 3600
tt <- gtfs_traveltimes (
    gtfs,
    from = from,
    start_time_limits = start_time_limits
)
head (tt)

## -----------------------------------------------------------------------------
nrow (tt)

## -----------------------------------------------------------------------------
nrow (gtfs$stops)

## ----maxtt--------------------------------------------------------------------
hms::hms (as.integer (max (tt$duration)))

## ----get-vbb, eval = FALSE----------------------------------------------------
#  gtfs <- extract_gtfs ("/<path>/<to>/vbb.zip")
#  gtfs <- gtfs_timetable (gtfs, day = 3)
#  tt <- gtfs_traveltimes (
#      gtfs,
#      from = from,
#      start_time_limits = start_time_limits
#  )
#  nrow (tt)
#  hms::hms (as.integer (max (tt$duration)))
#  ## [1] 8556
#  ## 01:00:00

## ----timing1, eval = FALSE----------------------------------------------------
#  maxt <- 3600 + 0:10 * 1800 # 1-6 hours in half-hour intervals
#  dat <- vapply (
#      maxt, function (i) {
#          st <- system.time (
#              res <- gtfs_traveltimes (
#                  gtfs,
#                  from = from,
#                  start_time_limits = start_time_limits,
#                  max_traveltime = i
#              )
#          )
#          return (c (st [3], nrow (res))) },
#      numeric (2)
#  )
#  dat <- data.frame (
#      max_time = maxt / 3600, # in hours
#      calc_time = dat [1, ],
#      n_stns = dat [2, ] / 1000
#  )
#  par (mfrow = c (1, 2))
#  plot (dat$max_time, dat$calc_time,
#      pch = 19, col = "gray",
#      xlab = "Max Traveltime (hours)",
#      ylab = "Calculation Time (seconds)"
#  )
#  lines (dat$max_time, dat$calc_time)
#  plot (dat$n_stns, dat$calc_time,
#      pch = 19, col = "gray",
#      xlab = "Thousands of Stations Reached",
#      ylab = "Calculation Time (seconds)"
#  )
#  lines (dat$n_stns, dat$calc_time)

## ----timing-manual, echo = FALSE----------------------------------------------
maxt <- 3600 + 0:10 * 1800
calc_time <- c (
    0.914, 1.246, 1.911, 2.156, 2.333, 2.513, 2.889, 3.344, 3.784,
    4.200, 4.661
)
n_stns <- c (
    8556, 12530, 15989, 19364, 21752, 23628, 24628, 25004, 25191,
    25295, 25352
)
dat <- data.frame (
    max_time = maxt / 3600, # in hours
    calc_time = calc_time,
    n_stns = n_stns / 1000
)
par (mfrow = c (1, 2))
plot (dat$max_time, dat$calc_time,
    pch = 19, col = "gray",
    xlab = "Max Traveltime (hours)",
    ylab = "Calculation Time (seconds)"
)
lines (dat$max_time, dat$calc_time)
plot (dat$n_stns, dat$calc_time,
    pch = 19, col = "gray",
    xlab = "Thousands of Stations Reached",
    ylab = "Calculation Time (seconds)"
)
lines (dat$n_stns, dat$calc_time)

## ----vbb-stops, eval = FALSE--------------------------------------------------
#  nrow (gtfs$stops)
#  ## [1] 41577

## ----vbb-stop-names, eval = FALSE---------------------------------------------
#  length (unique (gtfs$stops$stop_name))
#  ## [1] 13090

## ----vbb-2hours, eval = FALSE-------------------------------------------------
#  nrow (gtfs_traveltimes (
#      gtfs,
#      from = from,
#      start_time_limits = start_time_limits,
#      max_traveltime = 7200
#  ))
#  ## [1] 15989

## ----min-transfers, eval = FALSE----------------------------------------------
#  tt_fastest <- gtfs_traveltimes (
#      gtfs,
#      from = from,
#      start_time_limits = start_time_limits
#  )
#  tt_min_tr <- gtfs_traveltimes (
#      gtfs,
#      from = from,
#      start_time_limits = start_time_limits,
#      minimise_transfers = TRUE
#  )
#  # non-dplyr join:
#  tt_fastest <- tt_fastest [tt_fastest$stop_id %in% tt_min_tr$stop_id, ]
#  tt_min_tr <- tt_min_tr [tt_min_tr$stop_id %in% tt_fastest$stop_id, ]
#  dat <- data.frame (
#      stop_id = tt_fastest$stop_id,
#      fastest_dur = as.numeric (tt_fastest$duration / 3600), # hours
#      fastest_ntr = tt_fastest$ntransfers,
#      min_tr_dur = as.numeric (tt_min_tr$duration / 3600),
#      min_tr_ntr = tt_min_tr$ntransfers
#  )
#  
#  60 * mean (dat$min_tr_dur - dat$fastest_dur) # in minutes
#  ## [1] 3.957052

## ----ntr-diff, eval = FALSE---------------------------------------------------
#  mean (dat$fastest_ntr - dat$min_tr_ntr)
#  ## [1] 0.2818428

## ----ntr-prop, eval = FALSE---------------------------------------------------
#  length (which (dat$min_tr_ntr == dat$fastest_ntr)) / nrow (dat)
#  ## [1] 0.6875221

