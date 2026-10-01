\name{mlsas_local_test}
\alias{mlsas_local_test}
\title{Local Randomization Inference}
\description{Test each region using conditional or total label randomization and adjust local p-values.}
\usage{
mlsas_local_test(object, randomization = "conditional", alternative = "two.sided", 
    nperm = 99999L, seed = NULL, alpha = 0.05, p_adjust = "BH", 
    keep = FALSE, verbose = TRUE, progress = interactive(), permutations = NULL) 
}
\arguments{
\item{object}{An mlsas_stat object returned by mlsas_stat().}
\item{randomization}{conditional fixes the focal profile; total permutes all profile labels jointly. Local default is conditional.}
\item{alternative}{two.sided (default), greater, or less. Two-sided p is min(1, 2 * min(p_high, p_low)).}
\item{nperm}{Positive integer Monte Carlo draws, default 99999. Explicit permutations override this value. With one draw, permutation standard deviations are NA.}
\item{seed}{NULL consumes the current R random-number stream. An integer sets a local reproducible stream and restores the caller RNG state afterwards. The integrated function uses one sequential stream for fitting and both tests.}
\item{alpha}{Significance threshold strictly between zero and one, default 0.05.}
\item{p_adjust}{A method accepted by stats::p.adjust, default BH. Applied across all input regions within this local test; not across separate models.}
\item{keep}{Logical; retain permutation statistics (regions by draws for a local test). Default FALSE avoids storing the full distribution.}
\item{verbose}{Logical; show start, stage and elapsed-time messages. Does not request interactive confirmation.}
\item{progress}{Logical; show actual completed tree/permutation counts. Default interactive(). Forest fitting reports running because the engine exposes no progress callback.}
\item{permutations}{Optional n by B matrix, each column a permutation of integers 1:n. Intended for paired tests and exact-enumeration checks. Even with exhaustive inputs, the documented Monte Carlo +1 p-value convention is retained.}
}
\value{An mlsas_test list with table, settings and optional permutation statistics.}
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
s <- mlsas_similarity(d$x, ntree = 8, seed = 7,
                      verbose = FALSE, progress = FALSE)
o <- mlsas_stat(s, d$weights)
test <- mlsas_local_test(o, nperm = 19, seed = 8,
                           verbose = FALSE, progress = FALSE)
as.data.frame(test)
}
\seealso{\code{\link{mlsas_example}}, \code{\link{mlsas}}}
