# ML-SAS for R

**A Machine-Learning-Based Spatial Autocorrelation Statistic** for continuous, categorical
and mixed spatial data. Learn attribute similarity with an unsupervised random
forest, compute global and local ML-SAS, and perform permutation inference.

Authors: **Woohyung Kim and Sang-Il Lee**  
Maintainer: **Woohyung Kim** — whk3423@snu.ac.kr

## Install

```r
install.packages("remotes") # once, if needed
remotes::install_github("geowhk/ML-SAS-R", upgrade = "never")
```

Alternatively, download [mlsas_0.1.0.tar.gz](downloads/mlsas_0.1.0.tar.gz),
install missing dependencies, and select that file:

```r
install.packages(c("randomForest", "Matrix", "sf", "spdep"))
install.packages(file.choose(), repos = NULL, type = "source")
```

R >= 4.2 is required. Full package checks passed on macOS arm64 with R 4.5.2.
A user-run installation and example check also passed on Windows 10 x64 with R 4.5.1.
Spatial dependencies may need system libraries when installed from source.
The package has not been submitted to CRAN.

## Quick start

```r
library(mlsas)
d <- mlsas_example("mixed")
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

This small example explicitly reduces tree and permutation counts. Function
defaults follow the empirical analysis: 1,000 trees, path proximity, queen
contiguity with row-standardized weights, 99,999 permutations, total global
and conditional local randomization, two-sided tests and BH adjustment at 0.05.
Choose permutation counts appropriate to the desired p-value resolution.

## Input choices

- An `sf` object containing attributes and geometry: `data`.
- A data.frame/tibble plus separate `sf`: `data` and `spatial`.
- An attribute table plus an ID-labelled weight matrix: `data` and `weights`.

Select attributes explicitly with `variables`; connect regions using `id`.
Numeric, nominal factor and ordered-factor attributes are supported. Separate
inputs are aligned by ID. IDs and geometry do not enter forest training.

Weights support queen/rook polygons, distance or nearest-neighbour points, and
supplied matrices. Inference supports conditional/total local randomization,
one- or two-sided alternatives and standard p-value adjustment methods.
Use `verbose` and `progress` to control execution messages and progress bars.

## Documentation

- [PDF reference manual](docs/mlsas-reference-manual.pdf)
- [Getting started tutorial](vignettes/getting-started.Rmd)
- [Rendered tutorial](docs/getting-started.html) — download and open in a browser
- [Example R script](examples/quickstart.R)
- R help: `?mlsas`, `?mlsas_weights`, `?mlsas_local_test`

To install the in-R vignette as well, use
`remotes::install_github("geowhk/ML-SAS-R", upgrade="never", build_vignettes=TRUE)`
with knitr, rmarkdown and Pandoc available. The source archive above already
includes the rendered vignette.

## Validation and scope

The local `R CMD check` completed with **0 errors, 0 warnings and 0 notes**.
Tests cover exact enumeration on a small example, paper-engine numerical
comparisons, input alignment, spatial options, inference choices and
serial/parallel proximity equality. See [validation](docs/VALIDATION.json).
On Windows 10 x64 (build 19045), R 4.5.1, the maintainer reported successful
installation, a small mixed-data example (100 trees, 999 permutations), summary/map
output and one-/two-worker execution. This user-run check is separate from
`R CMD check`; the full Windows regression suite and Linux installation remain untested.

Version 0.1.0 uses dense similarity matrices and supports at most 31 nominal
factor levels. Missing/constant attributes and isolated regions are rejected
with explicit errors. Multiprocessing applies to proximity calculation;
forest fitting and permutation inference are serial.

## Related work

The accompanying paper has been accepted for publication. Its DOI and complete
citation will be added when available. The planned **ML-SAS-paper** repository
will contain the full paper-reproduction workflow and will be linked here after
publication. This repository contains the R package, examples and documentation.
The original DGP-generation source is excluded. A Python implementation is planned.

## License

MIT; see [LICENSE.md](LICENSE.md). Dependencies retain their own licenses.
