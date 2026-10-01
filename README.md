# ML-SAS for R

**A Machine-Learning-Based Spatial Autocorrelation Statistic** for continuous,
categorical and mixed spatial data. Compute global and local ML-SAS and perform
permutation tests using similarity learned by an unsupervised random forest.

## Installation

Requires R 4.2 or later.

```r
install.packages("remotes") # if needed
remotes::install_github("geowhk/ml-sas-r", upgrade = "never")
```

## Quick start

```r
library(mlsas)

# Small example dataset with attributes and geometry
d <- mlsas_example("mixed")

# Reduced tree and permutation counts for a quick first run
fit <- mlsas(
  data = d$data,
  variables = d$variables,
  id = d$id,
  ntree = 100,
  nperm = 999,
  seed = 2026
)

summary(fit)
head(as.data.frame(fit$local))
plot(fit)
```

Without overrides, the functions use the paper's empirical-analysis settings,
including 1,000 trees, 99,999 permutations and queen contiguity. Change only the
arguments you need; see the manual for all defaults and options. Large datasets
can require substantial time and memory. Use `progress = TRUE` to display progress.

## Your data

Choose one of three input forms:

- An `sf` object containing attributes and geometry: `data`.
- A data frame or tibble with separate `sf` geometry: `data` and `spatial`.
- An attribute table with a spatial weight matrix: `data` and `weights`.

Specify attribute columns with `variables` and a unique region identifier with
`id`. Separate inputs are matched by ID; supplied weight matrices must have
matching row and column IDs. Attributes may be numeric, nominal factors or
ordered factors. Missing values, constant attributes and regions without
neighbours must be resolved before analysis; nominal factors support up to 31 levels.

## Documentation

- [PDF reference manual](docs/mlsas-reference-manual.pdf)
- [Getting started tutorial](vignettes/getting-started.Rmd)
- [Example R script](examples/quickstart.R)
- In R: `?mlsas`

## Authors and license

Woohyung Kim and Sang-Il Lee.

Contact: whk3423@snu.ac.kr

[MIT license](LICENSE.md).
