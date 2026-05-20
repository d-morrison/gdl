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
#'   release date (or `start`, whichever is later) so the
#'   fetch covers exactly the data that will be plotted;
#'   `cranDownloads()`'s default of "yesterday only" produces
#'   a single-row result that cannot be plotted as a line.
#' @param start Optional lower-bound hint (a [Date]; callers
#'   that accept strings — e.g. [.get_download_data()] — are
#'   responsible for coercing/validating before passing here).
#'   When `from` is `NULL`, `from` is set to
#'   `max(first_release, start)` so that full package history
#'   is not fetched when only a bounded range is needed.
#' @param ... Additional arguments passed to
#'   [packageRank::cranDownloads()].
#'
#' @returns A tibble with columns `date`, `provider`, `new`,
#'   and `cumulative`.
#'
#' @keywords internal
.fetch_cran_downloads <- function(
  package, unit,
  from = NULL, to = NULL, start = NULL,
  ...
) {
  if (!requireNamespace("packageRank", quietly = TRUE)) {
    msg <- paste(
      "Package {.pkg packageRank} is required.",
      "Install with",
      "{.code install.packages('packageRank')}."
    )
    cli::cli_abort(msg)
  }

  if (is.null(from)) {
    first_release <- .cran_first_release_date(package)
    from <- if (!is.null(start)) {
      # Caller (.get_download_data) has already coerced `start` to a
      # valid Date if non-NULL.
      max(first_release, start)
    } else {
      first_release
    }
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
  dates <- if (is.null(history) || nrow(history) == 0L) {
    as.Date(character())
  } else {
    as.Date(history$Date)
  }
  dates <- dates[!is.na(dates)]
  if (length(dates) == 0L) {
    cli::cli_warn(c(
      "Could not look up CRAN release history for {.pkg {package}}.",
      i = "Falling back to one year of download data."
    ))
    return(Sys.Date() - 365L)
  }
  min(dates)
}
