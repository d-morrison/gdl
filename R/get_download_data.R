#' Fetch and prepare download data for plotting
#'
#' Fetches CRAN (and optionally GitHub) download data,
#' then combines, filters, and pivots into long format.
#'
#' @param package Character; CRAN package name to graph.
#' @param github_repo Character string `"owner/name"` for a
#'   GitHub repository to also include release-asset
#'   downloads from, or `NULL` (default) for CRAN only.
#' @param new Logical; include new (daily) downloads?
#'   Defaults to `TRUE`.
#' @param cumulative Logical; include cumulative downloads?
#'   Defaults to `TRUE`.
#' @param start Start date for the plot (a [Date] or string
#'   coercible to one). Defaults to `NULL` (all available
#'   data).
#' @param unit Character string specifying the time unit to
#'   aggregate by. One of `"day"`, `"week"`, `"month"`,
#'   `"quarter"`, or `"year"`. Defaults to `"month"`.
#' @param title Character string for the plot title. Defaults
#'   to a description including the package name and time
#'   unit. Set to `NULL` to omit.
#' @inheritDotParams packageRank::cranDownloads
#'
#' @returns A `download_data` tibble (subclass of
#'   `tbl_df`) with columns `date`, `provider`, `metric`,
#'   and `downloads`, plus attributes `title`,
#'   `github`, and `multi_metric`.
#'
#' @keywords internal
.get_download_data <- function(
  package,
  github_repo = NULL,
  new = TRUE,
  cumulative = TRUE,
  start = NULL,
  unit = c("month", "day", "week", "quarter", "year"),
  title,
  ...
) {
  if (!new && !cumulative) {
    msg <- paste(
      "At least one of {.arg new} or",
      "{.arg cumulative} must be {.val TRUE}."
    )
    cli::cli_abort(msg)
  }

  unit <- unit |> rlang::arg_match()

  cran_data <- .fetch_cran_downloads(package, unit, ...)
  github_data <- if (!is.null(github_repo)) {
    .fetch_github_downloads(github_repo, unit)
  }

  metrics <- c(
    if (new) "new",
    if (cumulative) "cumulative"
  )

  result <- .prepare_download_data(
    cran_data, github_data, start, metrics
  )

  if (missing(title)) {
    title <- paste0(
      "Downloads of ", package, " package from CRAN, by ",
      unit
    )
  }

  result |>
    structure(
      title = title,
      github = !is.null(github_repo),
      multi_metric = new && cumulative
    ) |>
    .subclass("download_data")
}
