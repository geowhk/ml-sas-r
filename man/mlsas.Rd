\name{mlsas}
\alias{mlsas}
\title{Run an ML-SAS Analysis}
\description{Fit attribute similarity and perform global and local spatial association tests. Default settings follow the empirical analysis in the accompanying paper.}
\usage{
mlsas(data, variables, id, spatial = NULL, weights = NULL, 
    contiguity = "queen", style = "W", proximity = "path", ntree = 1000L, 
    mtry = NULL, nodesize = 1L, nperm = 99999L, randomization = "conditional", 
    alternative = "two.sided", p_adjust = "BH", alpha = 0.05, 
    seed = NULL, workers = 1L, verbose = TRUE, progress = interactive()) 
}
\arguments{
\item{data}{An sf object or a data.frame/tibble containing attributes and the ID column.}
\item{variables}{Character vector selecting analysis columns explicitly. Exclude IDs and geometry. Numeric, factor and ordered-factor attributes are supported; no automatic encoding or imputation.}
\item{id}{Name of a unique, non-missing region ID column. Required for the integrated function. In the weights constructor, omitted IDs use row names.}
\item{spatial}{An sf object. Separate attribute and spatial tables must have identical ID sets; spatial rows are reordered to attribute order. The weights constructor also accepts a square, ID-labelled numeric matrix.}
\item{weights}{Square non-negative weights matrix with matching row and column IDs. Supplied weights are used as provided, without implicit standardization. Construct transformed weights with mlsas_weights first.}
\item{contiguity}{Polygon contiguity: queen includes shared vertices; rook requires a shared boundary segment.}
\item{style}{Weight transform: W row-standardizes, B makes positive edges binary, raw preserves supplied magnitudes. Applies when constructing weights, not to an existing matrix supplied to mlsas.}
\item{proximity}{Path uses the mean full-root-to-terminal path Jaccard similarity; terminal uses mean leaf co-membership.}
\item{ntree}{Positive integer number of trees. Default 1000 follows the empirical analysis.}
\item{mtry}{Number of candidate attributes per split. NULL uses max(1, floor(sqrt(number of attributes))), the classification forest rule used by the empirical code.}
\item{nodesize}{Positive integer minimum terminal node size; default 1 follows the empirical classification forest.}
\item{nperm}{Positive integer Monte Carlo draws, default 99999. Explicit permutations override this value. With one draw, permutation standard deviations are NA.}
\item{randomization}{conditional fixes the focal profile; total permutes all profile labels jointly. Local default is conditional.}
\item{alternative}{two.sided (default), greater, or less. Two-sided p is min(1, 2 * min(p_high, p_low)).}
\item{p_adjust}{A method accepted by stats::p.adjust, default BH. Applied across all input regions within this local test; not across separate models.}
\item{alpha}{Significance threshold strictly between zero and one, default 0.05.}
\item{seed}{NULL consumes the current R random-number stream. An integer sets a local reproducible stream and restores the caller RNG state afterwards. The integrated function uses one sequential stream for fitting and both tests.}
\item{workers}{Positive number of proximity-calculation workers, default 1. Forest fitting and permutation tests are serial in version 0.1.0. Fixed tree groups retain summation order across worker counts.}
\item{verbose}{Logical; show start, stage and elapsed-time messages. Does not request interactive confirmation.}
\item{progress}{Logical; show actual completed tree/permutation counts. Default interactive(). Forest fitting reports running because the engine exposes no progress callback.}
}
\value{An mlsas_fit list containing statistic, global, local, similarity, spatial and settings.}
\details{
Self-similarity and weight diagonals are excluded. With n regions,
\eqn{P = n(n-1) W / \sum W} and \eqn{Q = S / \sum S}.
The global statistic is \eqn{\sum_{ij} P_{ij} Q_{ij}} and the local
statistic is \eqn{n \sum_j P_{ij}Q_{ij}}. The local average equals global ML-SAS.
The fitted representation is held fixed during inference. Tail counts include ties;
Monte Carlo p-values use (count + 1)/(B + 1).
Significant locations above their permutation mean are similarity clusters; those
below it are dissimilarity/outliers. These are not univariate High-High/Low-Low labels.
An equality to the permutation mean is not assigned a directional discovery.
All-tied distributions yield p = 1. No observations are silently removed.
Dense similarity storage is quadratic in n. Inference streams batches of 256 draws.
User-supplied permutation indices use additional n by B storage.
}
\examples{
d <- mlsas_example()
fit <- mlsas(d$data, d$variables, d$id, ntree = 8, nperm = 19,
             seed = 7, verbose = FALSE, progress = FALSE)
summary(fit)
}
\seealso{\code{\link{mlsas_example}}, \code{\link{mlsas}}}
