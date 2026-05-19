
<!-- README.md is generated from README.Rmd. Please edit that file -->

# `{gdl}` (Graph DownLoads)

<!-- badges: start -->
<!-- badges: end -->

`{gdl}` plots new and cumulative download counts for an R package over
time, combining CRAN data (via
[`packageRank`](https://cran.r-project.org/package=packageRank)) with
optional GitHub Releases asset-download counts (via
[`gh`](https://github.com/r-lib/gh)).

## Installation

``` r
# install.packages("pak")
pak::pak("d-morrison/gdl")
```

## Usage

``` r
library(gdl)

# CRAN only
graph_downloads("dplyr")

# CRAN + GitHub Releases
graph_downloads("dplyr", github_repo = "tidyverse/dplyr")

# Weekly aggregation from a start date
graph_downloads("dplyr", unit = "week", start = "2024-01-01")

# Cumulative only
graph_downloads("dplyr", new = FALSE)
```

`graph_downloads()` returns a `ggplot` object, so you can post-process it
with the usual `+ theme(...)` and friends.
