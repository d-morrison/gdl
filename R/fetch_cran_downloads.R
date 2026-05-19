#' Fetch and aggregate CRAN download counts
#'
#' Uses [packageRank::cranDownloads()] to fetch daily CRAN
#' download data with cumulative counts, then aggregates by
#' `unit`.
#'
#' @param package Character; CRAN package name.
#' @param unit Character string passed to [cut.Date()] for
#'   time aggregation (e.g. `"month"`, `"week"`).
#' @param from,to Date range passed to
#'   [packageRank::cranDownloads()]. If `from` is `NULL`
#'   (the default), it is set to the package's first CRAN
#'   release date so the full history is fetched;
#'   `cranDownloads()`'s default of "yesterday only" produces
#'   a single-row result that cannot be plotted as a line.
#' @param ... Additional arguments passed to
#'   [packageRank::cranDownloads()].
#'
#' @returns A tibble with columns `date`, `provider`, `new`,
#'   and `cumulative`.
#'
#' @keywords internal
.fetch_cran_downloads <- function(package, unit, from = NULL, to = NULL, ...) {
  if (!requireNamespace("packageRank", quietly = TRUE)) {
    msg <- paste(
      "Package {.pkg packageRank} is required.",
      "Install with",
      "{.code install.packages('packageRank')}."
    )
    cli::cli_abort(msg)
  }

  if (is.null(from)) {
    from <- .cran_first_release_date(package)
  }

  dl <- packageRank::cranDownloads(package, from = from, to = to, ...)

  dl$cranlogs.data |>
    dplyr::rename(new = "count") |>
    dplyr::mutate(provider = "CRAN") |>
    dplyr::select("date", "provider", "new", "cumulative") |>
    .aggregate_by_unit(unit)
}

# Earliest CRAN release date for `package`, or 1 year ago if
# the history lookup fails (e.g. archived package, network error).
.cran_first_release_date <- function(package) {
  history <- tryCatch(
    packageRank::packageHistory(package),
    error = function(e) NULL
  )
  if (is.null(history) || nrow(history) == 0L) {
    return(Sys.Date() - 365L)
  }
  min(as.Date(history$Date), na.rm = TRUE)
}
