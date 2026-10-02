# ML-SAS: small mixed-data example
# Install first: remotes::install_github("geowhk/ml-sas-r")
library(mlsas)
d <- mlsas_example("mixed")
# Reduced counts make this a quick introduction.
fit <- mlsas(d$data, variables=d$variables, id=d$id,
             ntree=100, nperm=999, seed=2026, progress=interactive())
summary(fit)
head(as.data.frame(fit$local))
plot(fit)
# Omit ntree/nperm to use 1,000 trees and 99,999 permutations.
# For separate inputs: data=d$attributes, spatial=d$spatial.
# Reuse similarity with a different spatial neighbourhood:
w <- mlsas_weights(d$data, id=d$id, contiguity="rook")
o <- mlsas_stat(fit$similarity,w)
local <- mlsas_local_test(o,nperm=999,seed=2027)
head(as.data.frame(local))
