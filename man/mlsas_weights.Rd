\name{mlsas_weights}
\alias{mlsas_weights}
\title{Construct Spatial Weights}
\description{Construct contiguity, distance or nearest-neighbour weights, or transform an existing matrix.}
\usage{
mlsas_weights(spatial, id = NULL, method = c("contiguity", "distance", 
    "knn"), contiguity = c("queen", "rook"), style = c("W", "B", 
    "raw"), distance = NULL, k = 4L, symmetrize = c("union", 
    "mutual", "none")) 
}
\arguments{
\item{spatial}{An sf object. Separate attribute and spatial tables must have identical ID sets; spatial rows are reordered to attribute order. The weights constructor also accepts a square, ID-labelled numeric matrix.}
\item{id}{Name of a unique, non-missing region ID column. Required for the integrated function. In the weights constructor, omitted IDs use row names.}
\item{method}{Neighbour construction: contiguity, distance or knn. Distance and knn require POINT geometry with known CRS; choose polygon representative points explicitly.}
\item{contiguity}{Polygon contiguity: queen includes shared vertices; rook requires a shared boundary segment.}
\item{style}{Weight transform: W row-standardizes, B makes positive edges binary, raw preserves supplied magnitudes. Applies when constructing weights, not to an existing matrix supplied to mlsas.}
\item{distance}{Positive threshold in the units returned by sf::st_distance; metres for longitude/latitude. Required with method = distance.}
\item{k}{Positive integer smaller than the region count for nearest neighbours, default 4. Equal distances are broken by region ID.}
\item{symmetrize}{For knn: union, mutual or none. Directed weights are retained with none. Isolated regions always produce an error.}
}
\value{A numeric matrix with region-ID dimnames and a settings attribute.}
\details{Queen/rook requires valid nonempty polygons. Point distances use the supplied CRS. Isolated regions are rejected with their IDs. No automatic CRS transformation, imputation, geometry repair or region deletion occurs. For advanced distance/knn analyses, construct weights first and supply an attribute table plus weights to mlsas.}
\examples{
d <- mlsas_example()
w <- mlsas_weights(d$data, id = "region_id", contiguity = "rook")
head(rowSums(w))
}
\seealso{\code{\link{mlsas_example}}, \code{\link{mlsas}}}
