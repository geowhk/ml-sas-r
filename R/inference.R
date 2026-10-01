.test <- function(object, local, randomization, alternative, nperm, seed,
                  alpha, p_adjust, keep, verbose, progress, permutations) {
  if(!inherits(object,"mlsas_stat")) stop("object must come from mlsas_stat().")
  alternative<-match.arg(alternative,c("two.sided","greater","less"))
  randomization<-match.arg(randomization,c("conditional","total"))
  if(length(alpha)!=1L || !is.finite(alpha) || alpha<=0 || alpha>=1) stop("alpha must be between 0 and 1.")
  p_adjust<-match.arg(p_adjust,stats::p.adjust.methods)
  n<-length(object$ids)
  if(!is.null(permutations)) {
    if(!is.matrix(permutations) || !is.numeric(permutations) || nrow(permutations)!=n || ncol(permutations)<1L || anyNA(permutations) || any(permutations!=floor(permutations)) || any(permutations<1L | permutations>n)) stop("permutations must have n rows and valid integer labels 1:n.")
    if(!all(apply(permutations,2,function(z) identical(sort(as.integer(z)),seq_len(n))))) stop("Each permutation column must contain every label exactly once.")
    nperm<-ncol(permutations)
  }
  nperm<-.integer(nperm,"nperm");restore<-.seed(seed);on.exit(restore(),add=TRUE)
  observed<-if(local) object$local else object$global;m<-length(observed)
  high<-low<-numeric(m);avg<-numeric(m);M2<-numeric(m);done<-0L
  saved<-if(keep) matrix(NA_real_,m,nperm) else NULL
  start<-proc.time()[3]
  if(verbose) message(if(local) paste("Local",randomization) else "Global total-label"," permutation test: ",format(nperm,big.mark=",")," permutations. This may take several minutes.")
  pb<-.progress(nperm,progress);on.exit(pb$close(),add=TRUE)
  for(first in seq.int(1L,nperm,by=256L)) {
    ix<-first:min(nperm,first+255L);b<-length(ix)
    pi<-if(is.null(permutations)) vapply(ix,function(j) sample.int(n),integer(n)) else permutations[,ix,drop=FALSE]
    values<-matrix(0,m,b)
    if(local && randomization=="conditional") {
      for(i in seq_len(n)) {
        neighbours<-which(object$P[i,]!=0)
        assigned<-pi[neighbours,,drop=FALSE];displaced<-assigned==i
        replacement<-matrix(pi[i,],length(neighbours),b,byrow=TRUE)
        assigned[displaced]<-replacement[displaced]
        q<-matrix(object$Q[i,assigned],length(neighbours),b)
        values[i,]<-n*colSums(q*object$P[i,neighbours])
      }
    } else {
      for(j in seq_len(b)) {
        prod<-object$P*object$Q[pi[,j],pi[,j],drop=FALSE]
        values[,j]<-if(local) n*rowSums(prod) else sum(prod)
      }
    }
    high<-high+rowSums(values>=observed);low<-low+rowSums(values<=observed)
    bm<-rowMeans(values);delta<-bm-avg
    M2<-M2+rowSums((values-bm)^2)+delta^2*done*b/(done+b)
    avg<-avg+delta*b/(done+b);done<-done+b
    if(keep) saved[,ix]<-values
    pb$tick(done)
  }
  ph<-(high+1)/(nperm+1);pl<-(low+1)/(nperm+1)
  p<-switch(alternative,greater=ph,less=pl,two.sided=pmin(1,2*pmin(ph,pl)))
  adjusted<-if(local) stats::p.adjust(p,p_adjust) else p
  direction<-ifelse(observed>avg,"Similarity cluster",ifelse(observed<avg,"Dissimilarity/outlier","At expectation"))
  appropriate<-switch(alternative,greater=observed>avg,less=observed<avg,two.sided=observed!=avg)
  tab<-data.frame(id=if(local) object$ids else "global",statistic=observed,permutation_mean=avg,permutation_sd=if(nperm>1L) sqrt(pmax(0,M2/(nperm-1))) else NA_real_,p_high=ph,p_low=pl,p_value=p,p_adjusted=adjusted,classification=ifelse(adjusted<=alpha & appropriate,direction,"Not significant"),row.names=NULL)
  if(verbose) message("Permutation test completed in ",round(proc.time()[3]-start,2)," seconds.")
  structure(list(table=tab,settings=list(scope=if(local) "local" else "global",randomization=if(local) randomization else "total",alternative=alternative,nperm=nperm,alpha=alpha,p_adjust=if(local) p_adjust else "none",seed=seed,explicit_permutations=!is.null(permutations),elapsed=unname(proc.time()[3]-start),R=R.version.string,RNGkind=RNGkind(),version=as.character(utils::packageVersion("mlsas"))),permutations=saved),class="mlsas_test")
}
mlsas_global_test <- function(object, alternative="two.sided", nperm=99999L,
                              seed=NULL, alpha=0.05, keep=FALSE, verbose=TRUE,
                              progress=interactive(), permutations=NULL) {
  .test(object,FALSE,"total",alternative,nperm,seed,alpha,"none",keep,verbose,progress,permutations)
}
mlsas_local_test <- function(object, randomization="conditional", alternative="two.sided",
                             nperm=99999L, seed=NULL, alpha=0.05, p_adjust="BH",
                             keep=FALSE, verbose=TRUE, progress=interactive(), permutations=NULL) {
  .test(object,TRUE,randomization,alternative,nperm,seed,alpha,p_adjust,keep,verbose,progress,permutations)
}
mlsas <- function(data, variables, id, spatial=NULL, weights=NULL,
                  contiguity="queen", style="W", proximity="path", ntree=1000L,
                  mtry=NULL, nodesize=1L, nperm=99999L, randomization="conditional",
                  alternative="two.sided", p_adjust="BH", alpha=0.05, seed=NULL,
                  workers=1L, verbose=TRUE, progress=interactive()) {
  if(!is.data.frame(data)) stop("data must be a data.frame, tibble or sf.")
  if(missing(id) || length(id)!=1L || !id %in% names(data)) stop("id must name a region ID column.")
  ids<-.ids(data[[id]],nrow(data))
  if(missing(variables) || !is.character(variables) || !length(variables) || anyDuplicated(variables) || any(!variables %in% names(data)) || id %in% variables) stop("Select unique attribute columns explicitly in variables, excluding id.")
  geometry<-NULL
  if(inherits(data,"sf")) {
    if(!is.null(spatial)) stop("Do not supply spatial when data already contains geometry.")
    if(!is.null(weights)) stop("Use a separate attribute table with weights; sf plus weights is ambiguous.")
    spatial<-data;data<-sf::st_drop_geometry(data)
  }
  if(!is.null(spatial) && !is.null(weights)) stop("Supply spatial OR weights, not both.")
  if(!is.null(spatial)) {
    if(!inherits(spatial,"sf") || !id %in% names(spatial)) stop("spatial must be sf with the same ID column.")
    spatial_ids<-.ids(spatial[[id]],nrow(spatial))
    if(!setequal(ids,spatial_ids)) stop("Region IDs in attributes and spatial data do not match; no rows were dropped.")
    spatial<-spatial[match(ids,spatial_ids),];geometry<-spatial[,id,drop=FALSE]
    weights<-mlsas_weights(spatial,id=id,contiguity=contiguity,style=style)
  } else {
    if(is.null(weights)) stop("Provide sf geometry or an ID-labelled weights matrix.")
    # Supplied weights have already been constructed; never silently normalize again.
    weights<-.matrix(weights,"weights")
  }
  if(!setequal(ids,rownames(weights))) stop("Region IDs in attributes and weights do not match.")
  x<-as.data.frame(data)[,variables,drop=FALSE];rownames(x)<-ids
  restore<-.seed(seed);on.exit(restore(),add=TRUE)
  s<-mlsas_similarity(x,proximity,ntree,mtry,nodesize,workers=workers,verbose=verbose,progress=progress)
  stat<-mlsas_stat(s,weights)
  global<-mlsas_global_test(stat,alternative,nperm,alpha=alpha,verbose=verbose,progress=progress)
  local<-mlsas_local_test(stat,randomization,alternative,nperm,alpha=alpha,p_adjust=p_adjust,verbose=verbose,progress=progress)
  structure(list(statistic=stat,global=global,local=local,similarity=s,spatial=geometry,settings=list(seed=seed,variables=variables,id=id,workers=workers,version=as.character(utils::packageVersion("mlsas")),R=R.version.string,RNGkind=RNGkind())),class="mlsas_fit")
}
