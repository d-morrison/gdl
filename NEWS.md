# gdl 0.0.0.9001

* Fixed gh-pages site root returning 404 before the first stable release: dev
  deploys now drop a small `index.html` redirect at the root pointing to `/dev/`.
* `graph_downloads()` examples now render output in altdoc docs builds while
  skipping in offline R CMD check. Gated on a docs-only env var
  (`@examplesIf interactive() || nzchar(Sys.getenv("GDL_DOCS_BUILD"))`),
  which the docs workflow sets but R-CMD-check does not.
* `.fetch_cran_downloads()` now accepts a `start` hint so only the requested
  date range is fetched from CRAN, avoiding a full-history download when a
  bounded `start` date is supplied.

# gdl 0.0.0.9000

* Initial development version.
* `graph_downloads()` plots new and cumulative download counts for an R
  package over time, combining CRAN data (via `packageRank::cranDownloads()`)
  with optional GitHub Releases asset-download counts (via `gh`).
* Configurable time-unit aggregation (`"day"`, `"week"`, `"month"`,
  `"quarter"`, `"year"`), start-date filtering, and custom titles.
* Custom S3 class `download_data` with an `autoplot()` method so callers
  can fetch data and plot in separate steps.
