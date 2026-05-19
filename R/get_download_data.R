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

  # Coerce + validate `start` once here so both .fetch_cran_downloads()
  # (which uses it as a fetch lower-bound) and .prepare_download_data()
  # (which uses it to post-filter the combined CRAN+GitHub frame) see
  # the same validated Date. Without this, an invalid `start` silently
  # filters every row out downstream. as.Date() can either error
  # (character without a recognized format) or return NA (e.g. from
  # NA input), so handle both.
  if (!is.null(start)) {
    coerced <- tryCatch(as.Date(start), error = function(e) NULL)
    if (is.null(coerced) || is.na(coerced)) {
      cli::cli_abort(c(
        "{.arg start} could not be coerced to a Date.",
        x = "Got {.val {start}}."
      ))
    }
    start <- coerced
  }

  # `start` is passed in twice: here to bound the actual CRAN fetch,
  # and in .prepare_download_data() to post-filter both sources. The
  # post-filter is a no-op for CRAN once we pass `start` here, but
  # still filters the GitHub side (which fetches all releases).
  cran_data <- .fetch_cran_downloads(package, unit, start = start, ...)
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
