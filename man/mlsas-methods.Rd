\name{mlsas-methods}
\alias{print.mlsas_fit}\alias{print.mlsas_stat}\alias{print.mlsas_test}
\alias{summary.mlsas_fit}\alias{summary.mlsas_test}
\alias{as.data.frame.mlsas_test}\alias{plot.mlsas_fit}\alias{plot.mlsas_test}
\title{Inspect ML-SAS Results}
\description{Display observed statistics, test tables, effective settings, and maps or index plots.}
\usage{
\method{print}{mlsas_fit}(x, ...)
\method{print}{mlsas_stat}(x, ...)
\method{print}{mlsas_test}(x, ...)
\method{summary}{mlsas_fit}(object, ...)
\method{summary}{mlsas_test}(object, ...)
\method{as.data.frame}{mlsas_test}(x, row.names = NULL, optional = FALSE, ...)
\method{plot}{mlsas_fit}(x, ...)
\method{plot}{mlsas_test}(x, ...)
}
\arguments{
\item{x, object}{An ML-SAS result of the corresponding class.}
\item{row.names, optional}{Passed to the data.frame conversion.}
\item{...}{Additional printing or plotting arguments; unused by summary methods.}
}
\value{Print and plot return the input invisibly. Summary returns tables and settings; as.data.frame returns the test table.}
\details{A fitted object with geometry plots local classes on that geometry. Without geometry it plots local statistics against region index. Test plots also use region index.}
