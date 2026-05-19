#' Plot package download counts over time by source
#'
#' Fetches download data from CRAN (via `packageRank`) and
#' optionally GitHub Releases (via `gh`), then plots new and
#' cumulative downloads.
#'
#' @inheritParams .get_download_data
#' @inheritDotParams .get_download_data
#'
#' @return A [ggplot2::ggplot()] object with faceted panels.
#'
#' @details
#' GitHub release downloads are cumulative counts per release
#' asset from the GitHub API. New GitHub downloads are derived
#' as the contribution of each release. CRAN downloads are
#' fetched via [packageRank::cranDownloads()].
#'
#' Requires the `packageRank` package (and `gh` if
#' `github_repo` is set), listed under `Suggests`.
#'
#' @examplesIf interactive() || identical(Sys.getenv("CI"), "true")
#' graph_downloads("dplyr")
#' graph_downloads("dplyr", github_repo = "tidyverse/dplyr")
#' graph_downloads("dplyr", unit = "week", start = "2024-01-01")
#'
#' @export
graph_downloads <- function(package, ...) {
  .get_download_data(package, ...) |> ggplot2::autoplot()
}
