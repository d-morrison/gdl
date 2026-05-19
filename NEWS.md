# gdl 0.0.0.9000

* Initial development version.
* `graph_downloads()` plots new and cumulative download counts for an R
  package over time, combining CRAN data (via `packageRank::cranDownloads()`)
  with optional GitHub Releases asset-download counts (via `gh`).
* Configurable time-unit aggregation (`"day"`, `"week"`, `"month"`,
  `"quarter"`, `"year"`), start-date filtering, and custom titles.
* Custom S3 class `download_data` with an `autoplot()` method so callers
  can fetch data and plot in separate steps.
