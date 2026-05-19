#' Fetch and aggregate CRAN download counts
#'
#' Uses [packageRank::cranDownloads()] to fetch daily CRAN
#' download data with cumulative counts, then aggregates by
#' `unit`.
#'
#' @param package Character; CRAN package name.
#' @param unit Character string passed to [cut.Date()] for
#'   time aggregation (e.g. `"month"`, `"week"`).
#' @param ... Additional arguments passed to
#'   [packageRank::cranDownloads()].
#'
#' @returns A tibble with columns `date`, `provider`, `new`,
#'   and `cumulative`.
#'
#' @keywords internal
.fetch_cran_downloads <- function(package, unit, ...) {
  if (!requireNamespace("packageRank", quietly = TRUE)) {
    msg <- paste(
      "Package {.pkg packageRank} is required.",
      "Install with",
      "{.code install.packages('packageRank')}."
    )
    cli::cli_abort(msg)
  }

  dl <- packageRank::cranDownloads(package, ...)

  dl$cranlogs.data |>
    dplyr::rename(new = "count") |>
    dplyr::mutate(provider = "CRAN") |>
    dplyr::select("date", "provider", "new", "cumulative") |>
    .aggregate_by_unit(unit)
}
