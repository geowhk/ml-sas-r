\name{mlsas_example}
\alias{mlsas_example}
\title{Small Synthetic Spatial Examples}
\description{Return a deterministic 6 by 6 square lattice with continuous and categorical attributes for learning the API.}
\usage{
mlsas_example(type = c("mixed", "continuous")) 
}
\arguments{
\item{type}{mixed (numeric, nominal and ordered attributes) or continuous. Both return 36 synthetic lattice regions.}
}
\value{A list containing data (sf), attributes, spatial, x, weights, variables and id.}
\examples{
d <- mlsas_example()
names(d)
}
\seealso{\code{\link{mlsas_example}}, \code{\link{mlsas}}}
