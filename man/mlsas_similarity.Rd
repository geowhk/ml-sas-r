\name{mlsas_similarity}
\alias{mlsas_similarity}
\title{Learn Attribute Similarity}
\description{Fit an Addcl1 real-versus-synthetic classification forest and average path or terminal similarities.}
\usage{
mlsas_similarity(x, proximity = c("path", "terminal"), ntree = 1000L, 
    mtry = NULL, nodesize = 1L, seed = NULL, workers = 1L, verbose = TRUE, 
    progress = interactive(), synthetic = NULL) 
}
\arguments{
\item{x}{Attribute data.frame/tibble without geometry, with region IDs as row names. For S3 methods, a package result object.}
\item{proximity}{Path uses the mean full-root-to-terminal path Jaccard similarity; terminal uses mean leaf co-membership.}
\item{ntree}{Positive integer number of trees. Default 1000 follows the empirical analysis.}
\item{mtry}{Number of candidate attributes per split. NULL uses max(1, floor(sqrt(number of attributes))), the classification forest rule used by the empirical code.}
\item{nodesize}{Positive integer minimum terminal node size; default 1 follows the empirical classification forest.}
\item{seed}{NULL consumes the current R random-number stream. An integer sets a local reproducible stream and restores the caller RNG state afterwards. The integrated function uses one sequential stream for fitting and both tests.}
\item{workers}{Positive number of proximity-calculation workers, default 1. Forest fitting and permutation tests are serial in version 0.1.0. Fixed tree groups retain summation order across worker counts.}
\item{verbose}{Logical; show start, stage and elapsed-time messages. Does not request interactive confirmation.}
\item{progress}{Logical; show actual completed tree/permutation counts. Default interactive(). Forest fitting reports running because the engine exposes no progress callback.}
\item{synthetic}{Optional Addcl1 sample for paired checks: same dimensions, names, column classes and factor levels as x. NULL independently resamples each attribute with replacement.}
}
\value{A symmetric numeric similarity matrix, with region-ID dimnames and effective settings. Its diagonal is one; downstream statistics exclude the diagonal.}
\details{Numeric, nominal and ordered factors are supported. Missing values,
constant attributes and nominal factors with more than 31 levels are rejected in
this release. Ordered factors follow their declared order. The nominal-level
limit protects the inherited integer bit-mask path decoder. No factor is silently
one-hot encoded. Progress reporting does not alter forest fitting.
The full similarity matrix requires quadratic memory in the number of regions.}
\examples{
d <- mlsas_example()
s <- mlsas_similarity(d$x, ntree = 8, seed = 7,
                      verbose = FALSE, progress = FALSE)
s[1:3, 1:3]
}
\seealso{\code{\link{mlsas_example}}, \code{\link{mlsas}}}
