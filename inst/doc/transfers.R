## ----DTthread, echo = FALSE---------------------------------------------------
# Necessary for CRAN to avoid CPU / elapsed time ratios being too high
nthr <- data.table::setDTthreads (1)

## ----berlin_gtfs--------------------------------------------------------------
library (gtfsrouter)
f <- berlin_gtfs_to_zip ()
gtfs <- extract_gtfs (f, quiet = TRUE)

## ----transfers-struct---------------------------------------------------------
gtfs$transfers

## ----route1-------------------------------------------------------------------
gtfs_route (
    gtfs,
    from = "Friedrichstr.",
    to = "Rosenthaler Platz",
    start_time = 12 * 3600,
    day = "Monday"
)

## ----no-transfers-------------------------------------------------------------
gtfs$transfers <- NULL
gtfs_route (
    gtfs,
    from = "Friedrichstr.",
    to = "Rosenthaler Platz",
    start_time = 12 * 3600,
    day = "Monday"
)

## ----transfer-table-200-------------------------------------------------------
gtfs <- gtfs_transfer_table (gtfs, d_limit = 200)
gtfs_route (
    gtfs,
    from = "Friedrichstr.",
    to = "Rosenthaler Platz",
    start_time = 12 * 3600,
    day = "Monday"
)

## ----transfer-table-size------------------------------------------------------
gtfs <- extract_gtfs (f, quiet = TRUE) # 'f' is the location generated above
nrow (gtfs$transfers)
length (which (!duplicated (gtfs$transfers [, c ("from_stop_id", "to_stop_id")])))

## ----transfer-table-size-data, echo = FALSE-----------------------------------
n0 <- nrow (gtfs$transfers)
n1 <- length (which (!duplicated (gtfs$transfers [, c ("from_stop_id", "to_stop_id")])))

## ----transfer-table-regen-----------------------------------------------------
gtfs$transfers <- NULL
gtfs <- gtfs_transfer_table (gtfs)
nrow (gtfs$transfers)

## ----transfer-table-regen2----------------------------------------------------
gtfs <- extract_gtfs (f, quiet = TRUE)
gtfs <- gtfs_transfer_table (gtfs)
nrow (gtfs$transfers)

## ----transfer-table-extend----------------------------------------------------
gtfs <- extract_gtfs (f, quiet = TRUE)
vapply (0:10, function (i) {
    gtfs <- gtfs_transfer_table (gtfs, d_limit = i * 100)
    return (nrow (gtfs$transfers))
}, integer (1))

## ----transfers-reduce-d_lim---------------------------------------------------
gtfs <- gtfs_transfer_table (gtfs, d_limit = 100)
nrow (gtfs$transfers)

## ----transfers-reduce-d_lim2--------------------------------------------------
gtfs$transfers <- NULL
gtfs <- gtfs_transfer_table (gtfs, d_limit = 100)
nrow (gtfs$transfers)

## ----route2-------------------------------------------------------------------
r <- gtfs_route (
    gtfs,
    from = "Friedrichstr.",
    to = "Rosenthaler Platz",
    start_time = 12 * 3600,
    day = "Monday",
    include_ids = TRUE
)
stns <- r$stop_id [3:4] # the transfer station IDs
gtfs$stops [match (stns, gtfs$stops$stop_id), ]

## ----dist---------------------------------------------------------------------
s <- gtfs$stops [match (stns, gtfs$stops$stop_id), ]
as.numeric (geodist::geodist (s [1, ], s [2, ]))

## ----SU_routes----------------------------------------------------------------
S_routes <- gtfs$routes$route_id [grep ("^S", gtfs$routes$route_short_name)]
U_routes <- gtfs$routes$route_id [grep ("^U", gtfs$routes$route_short_name)]
S_trips <- gtfs$trips$trip_id [which (gtfs$trips$route_id %in% S_routes)]
U_trips <- gtfs$trips$trip_id [which (gtfs$trips$route_id %in% U_routes)]

## ----SU_stops-----------------------------------------------------------------
S_stops <- gtfs$stop_times$stop_id [which (gtfs$stop_times$trip_id %in% S_trips)]
S_stops <- unique (S_stops)
U_stops <- gtfs$stop_times$stop_id [which (gtfs$stop_times$trip_id %in% U_trips)]
U_stops <- unique (U_stops)

## ----SU_stops2----------------------------------------------------------------
S_stops <- S_stops [which (!S_stops %in% U_stops)]
U_stops <- U_stops [which (!U_stops %in% S_stops)]

## ----penalty------------------------------------------------------------------
index <- which ((gtfs$transfers$from_stop_id %in% S_stops &
    gtfs$transfers$to_stop_id %in% U_stops) |
    (gtfs$transfers$from_stop_id %in% U_stops &
        gtfs$transfers$to_stop_id %in% S_stops))
gtfs$transfers$min_transfer_time [index] <-
    gtfs$transfers$min_transfer_time [index] + 120

## ----route3-------------------------------------------------------------------
gtfs_route (
    gtfs,
    from = "Friedrichstr.",
    to = "Rosenthaler Platz",
    start_time = 12 * 3600,
    day = "Monday"
)

## ----transfer_penalties_fn----------------------------------------------------
gtfs$transfers <- NULL
gtfs <- gtfs_transfer_table (gtfs, d_limit = 500)

transfer_penalties <- function (gtfs, penalty = 120) {

    S_routes <- gtfs$routes$route_id [grep ("^S", gtfs$routes$route_short_name)]
    U_routes <- gtfs$routes$route_id [grep ("^U", gtfs$routes$route_short_name)]
    S_trips <- gtfs$trips$trip_id [which (gtfs$trips$route_id %in% S_routes)]
    U_trips <- gtfs$trips$trip_id [which (gtfs$trips$route_id %in% U_routes)]

    S_stops <- gtfs$stop_times$stop_id [which (gtfs$stop_times$trip_id %in% S_trips)]
    S_stops <- unique (S_stops)
    U_stops <- gtfs$stop_times$stop_id [which (gtfs$stop_times$trip_id %in% U_trips)]
    U_stops <- unique (U_stops)

    S_stops <- S_stops [which (!S_stops %in% U_stops)]
    U_stops <- U_stops [which (!U_stops %in% S_stops)]

    index <- which ((gtfs$transfers$from_stop_id %in% S_stops &
        gtfs$transfers$to_stop_id %in% U_stops) |
        (gtfs$transfers$from_stop_id %in% U_stops &
            gtfs$transfers$to_stop_id %in% S_stops))
    gtfs$transfers$min_transfer_time [index] <-
        gtfs$transfers$min_transfer_time [index] + 120

    return (gtfs)
}
gtfs <- transfer_penalties (gtfs)

## ----route4-------------------------------------------------------------------
gtfs_route (
    gtfs,
    from = "Friedrichstr.",
    to = "Rosenthaler Platz",
    start_time = 12 * 3600,
    day = "Monday"
)

## ----route4b------------------------------------------------------------------
r <- gtfs_route (
    gtfs,
    from = "Friedrichstr.",
    to = "Rosenthaler Platz",
    start_time = 12 * 3600,
    day = "Monday",
    include_ids = TRUE
)
s <- gtfs$stops [match (r$stop_id [2:3], gtfs$stops$stop_id), ]
as.numeric (geodist::geodist (s [1, ], s [2, ]))

## ----d_limit1-----------------------------------------------------------------
d_limit <- 1:20 * 100
n <- vapply (d_limit, function (i) {
    gtfs$transfer <- NULL
    gtfs <- gtfs_transfer_table (gtfs, d_limit = i)
    nrow (gtfs$transfers)
}, integer (1))
d_limit <- d_limit / 1000 # in km
n <- n / 1000 # in thousands
plot (
    d_limit, n,
    type = "l", col = "red", lwd = 2,
    xlab = "Maximal transfer distance",
    ylab = "Number of transfers (1000s)"
)

## ----travel_times_d_limit-fn, message = FALSE---------------------------------
library (dplyr)
library (hms) # 'parse_hms' function

travel_times_d_limit <- function (gtfs, from, d_limit = 200) {

    gtfs$transfers <- NULL
    gtfs <- gtfs_transfer_table (gtfs, d_limit = d_limit)
    gtfs <- transfer_penalties (gtfs)

    start_time_limits <- 12:13 * 3600

    get_one_times <- function (gtfs, from, start_time_limits) {

        x <- gtfs_traveltimes (
            gtfs,
            from = from,
            start_time_limits = start_time_limits,
            quiet = TRUE
        )
        ret <- NULL
        if (nrow (x) > 0) {
            # Convert duration to minutes:
            dur <- as.integer (parse_hms (x$duration)) / 60
            ret <- data.frame (
                from = from,
                to = x$stop_id,
                duration = dur
            )
        }

        return (ret)
    }

    res <- lapply (from, function (i) {
        get_one_times (gtfs, i, start_time_limits)
    })
    res <- do.call (rbind, res) %>%
        group_by (from, to) %>%
        summarise (duration = mean (duration), .groups = "drop")
    res$d_limit <- d_limit

    return (res)
}

## ----plot1, warning = FALSE, message = FALSE----------------------------------
set.seed (10L)
from <- sample (gtfs$stops$stop_name, size = 10)
d_limit <- 1:10 * 100
x <- lapply (d_limit, function (i) {
    travel_times_d_limit (gtfs, from = from, d_limit = i)
})
xall <- do.call (rbind, x) [, c ("from", "to")]
xall <- xall [which (!duplicated (xall)), ]

for (i in seq_along (x)) {

    y <- left_join (xall, x [[i]], by = c ("from", "to"))
    xall [paste0 ("d_", x [[i]]$d_limit [1])] <- y$duration
}

index <- which (xall$d_1000 != xall$d_100)
# record number of stations for which travel times did not change:
nsame <- nrow (xall) - length (index)

xall <- xall [index, ]
# travel times only:
times <- xall %>% select (!c ("from", "to"))
# differences with each increase in d_limit:
times <- t (apply (times, 1, function (i) {
    diff (i)
}))
times <- data.frame (t = as.vector (times))
library (ggplot2)
ggplot (times, aes (x = t)) +
    stat_bin (bins = 30, col = "red", fill = "orange") +
    scale_y_log10 () +
    xlab ("time difference (minutes)")

## ----transfer_difference_fn---------------------------------------------------
transfer_difference <- function (gtfs,
                                 nsamples = 10,
                                 d_limit = 200,
                                 day = "Monday",
                                 start_time_limits = 12:13 * 3600) {

    g1 <- data.table::copy (gtfs)
    g1 <- gtfs_timetable (g1, day = day)

    g2 <- data.table::copy (gtfs)
    g2 <- gtfs_transfer_table (g2, d_limit = d_limit, quiet = TRUE)
    g2 <- gtfs_timetable (g2, day = day)

    get1 <- function (gtfs, gtfs2, start_time_limits) {

        from <- sample (gtfs$stops$stop_name, size = 1)
        x1 <- gtfs_traveltimes (
            gtfs,
            from = from,
            start_time_limits = start_time_limits,
            quiet = TRUE
        )

        x2 <- gtfs_traveltimes (
            gtfs2,
            from = from,
            start_time_limits = start_time_limits,
            quiet = TRUE
        )

        if (nrow (x1) == 0L | nrow (x2) == 0L) {
            return (rep (NA, 2))
        }

        x2 <- data.frame (
            stop_id = x2$stop_id,
            duration2 = x2$duration
        )
        x2 <- dplyr::left_join (x1, x2, by = "stop_id")

        dat <- data.frame (
            x = as.integer (parse_hms (x2$duration)) / 60,
            y = as.integer (parse_hms (x2$duration2)) / 60
        )
        mod <- lm (y ~ x + 0, data = dat)
        return (c (
            prop = length (which (dat$x != dat$y)) / nrow (dat),
            change = as.numeric (mod$coefficients)
        ))
    }

    vapply (seq (nsamples), function (i) {
        get1 (g1, g2, start_time_limits)
    },
    numeric (2),
    USE.NAMES = FALSE
    )
}

## ----transfer_d_limit_results, warning = FALSE--------------------------------
d_limit <- 1:10 * 100
set.seed (1L)
d <- lapply (d_limit, function (i) {
    transfer_difference (
        gtfs,
        nsamples = 20,
        d_limit = i,
        day = "Monday",
        start_time_limits = 12:13 * 3600
    )
})
d <- lapply (seq_along (d_limit), function (i) {
    data.frame (
        d_limit = d_limit [i],
        prop = d [[i]] [1, ],
        change = d [[i]] [2, ]
    )
})
d <- do.call (rbind, d)

ggplot (d, aes (x = d_limit, y = change)) +
    geom_point (pch = 19, col = "orange") +
    geom_smooth (method = "loess", formula = "y ~ x")

## ----stuttgart-results, echo = FALSE, warning = FALSE-------------------------
d <- list ()

# 1
d [[1]] <- rbind (
    c (
        0.04787234, 0.3024283, 0.2137809, 0.4226190, 0.4782609, 0,
        0.1996497, 0.0324826, 0.3122142, 0.1051136, 0.1330166,
        0.1755486, 0.3659229, NA, 0.2471751, 0.03344482,
        0.3617021, 0.3400000, NA, 0.05964215
    ),
    c (
        0.97835370, 0.9045062, 0.9552470, 0.8157467, 0.8343242, 1,
        0.8956478, 0.9857173, 0.9197187, 0.9813956, 0.9488823,
        0.9505516, 0.8601199, NA, 0.9367492, 0.99126114,
        0.8190608, 0.9064265, NA, 0.97887272
    )
)

# 2
d [[2]] <- rbind (
    c (
        0.2675343, 0.3167203, 0.4016824, 0.3119881, 0.3680556,
        0.09902913, 0.1257367, 0.1349578, 0.1366906, 0.4723442,
        0.2439614, 0.2401575, 0.2959184, 0.1376147, 0.4624113,
        0.1189189, 0.2706450, 0.1621622, 0.01632653, 0.3847584
    ),
    c (
        0.9333812, 0.8716062, 0.8790074, 0.9153534, 0.8889449,
        0.97546764, 0.9747218, 0.9620882, 0.9235575, 0.8427352,
        0.8973988, 0.8534331, 0.8745992, 0.9666719, 0.8746626,
        0.9395889, 0.9442811, 0.9733787, 0.99658716, 0.8350441
    )
)

# 3
d [[3]] <- rbind (
    c (
        0.4449339, 0.3257576, 0.08494208, 0.07758621, 0.2345679,
        0.009615385, 0.1959877, 0.06282723, 0.05785124, 0.4670588,
        0.0562500, 0.1203704, 0.1000000, 0.1720779, 0.4771167,
        0.4372331, 0.2102273, 0.1291449, 0.4567901, 0
    ),
    c (
        0.8480413, 0.8881877, 0.97683839, 0.95861325, 0.8839587,
        0.990835401, 0.9353503, 0.97107607, 0.97832732, 0.8946960,
        0.9568263, 0.9783830, 0.9800815, 0.9538397, 0.8978858,
        0.8865221, 0.9256468, 0.9507978, 0.8657352, 1
    )
)

# 4
d [[4]] <- rbind (
    c (
        0.7241379, 0.2611807, 0.2901961, 0.02531646, 0.5215054,
        0.2336735, 0.5795779, 0.1518987, NA, 0.0625000, NA, 0,
        0.6513274, 0.4292683, 0.3418573, 0.1452703, 0.2619543,
        0.4628450, 0.2417375, 0.3950216
    ),
    c (
        0.7022668, 0.9451780, 0.8701041, 0.98733569, 0.8588725,
        0.9451916, 0.8372441, 0.9076009, NA, 0.9842143, NA, 1,
        0.7893403, 0.9412012, 0.9203506, 0.9627622, 0.9228610,
        0.8665221, 0.9418134, 0.9021016
    )
)

# 5
d [[5]] <- rbind (
    c (
        0.7239508, 0.8513952, 0.1402439, 0.1448468, 0.4007092,
        0.09883721, 0.08634538, 0.2936747, 0.7217235, 0.5807783,
        0.7090415, 0.1440678, 0.4746581, 0.2164179, 0.05633803,
        0.3898587, NA, 0.1363636, 0.6066116, 0.2217195
    ),
    c (
        0.8041968, 0.7696561, 0.9385228, 0.9466528, 0.8734857,
        0.97151782, 0.97918464, 0.9076568, 0.7783634, 0.8431704,
        0.7343155, 0.9412296, 0.8566643, 0.9716889, 0.99403550,
        0.9124251, NA, 0.9785596, 0.8332798, 0.9380071
    )
)

# 6
d [[6]] <- rbind (
    c (
        0.4354430, 0.6561666, 0.2995392, NA, 0.3553922, 0.3404826,
        0.2711864, 0.2535433, 0.4971098, 0.6451231, 0.117378, 0,
        0.6751592, 0.4408353, 0.6392199, 0.5826598, NA, 0.1823770,
        0.2105263, 0.1016043
    ),
    c (
        0.7925198, 0.8567067, 0.9134449, NA, 0.8825668, 0.9020107,
        0.9247888, 0.9654961, 0.8274002, 0.7975106, 0.979065, 1,
        0.7964435, 0.8632960, 0.8738289, 0.7831721, NA, 0.9436972,
        0.9274683, 0.9744991
    )
)

# 7
d [[7]] <- rbind (
    c (
        0.5275288, 0.8809990, 0.2042254, 0.2562101, 0, 0.3214286,
        0.3479730, 0.2478032, 0.3501229, 0.5036298, 0.0560000,
        0.7117819, 0.4114833, 0.2748092, 0.1865342, 0.2213115,
        0.1674208, 0.3247863, 0.01388889, 0.2974013
    ),
    c (
        0.8974057, 0.7428764, 0.9503437, 0.9217992, 1, 0.9228010,
        0.9036412, 0.9161946, 0.9596850, 0.8494607, 0.9632148,
        0.7661997, 0.8901800, 0.9080806, 0.9574235, 0.9429245,
        0.9445154, 0.9383823, 0.99440270, 0.9226305
    )
)

# 8
d [[8]] <- rbind (
    c (
        0.4239291, 0.6470588, 0.4225146, 0.2475728, 0.4358491,
        0.4682081, 0.8519306, 0.5047619, 0.03007519, 0.4723404,
        0.1925676, 0.2028470, 0.5584677, 0.2478386, 0.06122449, 0,
        0.1219512, 0.6993865, 0.3742455, NA
    ),
    c (
        0.9030931, 0.8842219, 0.8946512, 0.9000109, 0.8482130,
        0.9018473, 0.7631321, 0.6506485, 0.98723649, 0.8749593,
        0.9249907, 0.9497207, 0.8826570, 0.9193413, 0.97003127, 1,
        0.8942574, 0.8027865, 0.8630442, NA
    )
)

# 9
d [[9]] <- rbind (
    c (
        0.1160991, 0.4269663, 0.2256858, 0.3259604, 0.7434613,
        0.3766376, 0.3615819, 0.5671642, 0.1721311, 0.7014749,
        0.1000000, 0.07798165, 0.1622276, 0.4407583, 0.3865188,
        0.2470309, 0.3603175, 0.1516588, 0.3102310, 0.4602133
    ),
    c (
        0.9666432, 0.7528710, 0.9193014, 0.9227199, 0.7834500,
        0.8515732, 0.8863982, 0.8002182, 0.9434899, 0.7971016,
        0.9594046, 0.98316892, 0.9457987, 0.8288464, 0.9053315,
        0.8986293, 0.8698507, 0.9590871, 0.8651403, 0.8851207
    )
)

# 10
d [[10]] <- rbind (
    c (
        0.3747811, NA, 0.4325744, NA, 0.7301301, 0.06694561,
        0.2693267, 0.2651163, 0.5702840, 0.5865947, 0.6845638,
        0.1111111, 0.5206897, NA, 0.2322275, 0.2739726,
        0.03968254, 0.1763367, 0.9158513, 0.3980100
    ),
    c (
        0.8318046, NA, 0.8894870, NA, 0.8242255, 0.97770335,
        0.8996235, 0.8986981, 0.8131951, 0.8357680, 0.8225032,
        0.8502140, 0.8353131, NA, 0.9366721, 0.8817567,
        0.99278373, 0.9559705, 0.6732793, 0.8348557
    )
)

d <- lapply (seq_along (d_limit), function (i) {
    data.frame (
        d_limit = d_limit [i],
        prop = d [[i]] [1, ],
        change = d [[i]] [2, ]
    )
})
d <- do.call (rbind, d)

ggplot (d, aes (x = d_limit, y = change)) +
    geom_point (pch = 19, col = "orange") +
    geom_smooth (method = "loess", formula = "y ~ x")

## ----stuttgart-plot2, warning = FALSE-----------------------------------------
ggplot (d, aes (x = d_limit, y = prop)) +
    geom_point (pch = 19, col = "orange") +
    geom_smooth (method = "loess", formula = "y ~ x")

## ----DTthread-reset, echo = FALSE---------------------------------------------
data.table::setDTthreads (nthr)

