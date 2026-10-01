\name{mlsas_stat}
\alias{mlsas_stat}
\title{Compute Global and Local ML-SAS}
\description{Calculate observed statistics from a similarity matrix and spatial weights.}
\usage{
mlsas_stat(similarity, weights) 
}
\arguments{
\item{similarity}{Symmetric finite non-negative matrix with matching row/column region IDs. Its diagonal is excluded; positive off-diagonal sum is required. User-supplied similarities define the attribute representation used in the analysis.}
\item{weights}{Square non-negative weights matrix with matching row and column IDs. Supplied weights are used as provided, without implicit standardization. Construct transformed weights with mlsas_weights first.}
}
\value{An mlsas_stat object with global, local, normalized P and Q, region IDs and settings.}
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
o
}
\seealso{\code{\link{mlsas_example}}, \code{\link{mlsas}}}
