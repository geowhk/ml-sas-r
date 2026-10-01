.integer <- function(x, name, minimum = 1L) {
  if (length(x)!=1L || !is.numeric(x) || !is.finite(x) || x!=floor(x) || x<minimum || x>.Machine$integer.max)
    stop(name, " must be a finite integer >= ", minimum, call.=FALSE)
  as.integer(x)
}
.ids <- function(x, n) {
  if (is.null(x) || length(x)!=n || anyNA(x) || any(!nzchar(as.character(x))) || anyDuplicated(x))
    stop("Provide unique, non-missing region IDs.",call.=FALSE)
  as.character(x)
}
.seed <- function(seed) {
  if(is.null(seed)) return(function() invisible(NULL))
  seed <- .integer(seed,"seed",0L)
  had <- exists(".Random.seed",.GlobalEnv,inherits=FALSE)
  if(had) old <- get(".Random.seed",.GlobalEnv)
  set.seed(seed)
  function() {if(had) assign(".Random.seed",old,.GlobalEnv) else if(exists(".Random.seed",.GlobalEnv,inherits=FALSE)) rm(".Random.seed",envir=.GlobalEnv)}
}
.progress <- function(total, enabled) {
  if(!isTRUE(enabled)) return(list(tick=function(i) NULL, close=function() NULL))
  bar <- utils::txtProgressBar(min=0,max=total,style=3)
  list(tick=function(i) utils::setTxtProgressBar(bar,i),close=function() close(bar))
}
.attributes <- function(x) {
  if(!is.data.frame(x) || inherits(x,"sf") || nrow(x)<3L || ncol(x)<1L)
    stop("x must be a data.frame/tibble with >=3 rows and >=1 attribute, without geometry.",call.=FALSE)
  x <- as.data.frame(x)
  if(anyDuplicated(names(x)) || any(!nzchar(names(x)))) stop("Attribute names must be unique.")
  for(nm in names(x)) {
    z <- x[[nm]]
    if(!(is.numeric(z) || is.factor(z)) || anyNA(z)) stop("Column '",nm,"' must be numeric or a factor, without missing values.",call.=FALSE)
    if(is.numeric(z) && any(!is.finite(z))) stop("Non-finite values in ",nm)
    if(is.factor(z) && (!is.ordered(z)) && nlevels(z)>31L) stop("Nominal factors support at most 31 levels in this release.")
    if(length(unique(z))<2L) stop("Constant attribute: ",nm,call.=FALSE)
  }
  x
}
.matrix <- function(x, label, symmetric=FALSE) {
  if(!(is.matrix(x) || inherits(x,"Matrix"))) stop(label," must be a matrix.")
  x <- as.matrix(x)
  if(!is.numeric(x) || nrow(x)!=ncol(x) || nrow(x)<3L || any(!is.finite(x)) || any(x<0)) stop(label," must be square, finite, non-negative, with >=3 regions.")
  ids <- .ids(rownames(x),nrow(x))
  if(!identical(ids,colnames(x))) stop(label," row and column IDs must match in order.")
  if(symmetric && max(abs(x-t(x)))>1e-12) stop(label," must be symmetric.")
  diag(x)<-0
  if(sum(x)<=0) stop(label," has no positive off-diagonal values.")
  x
}
mlsas_weights <- function(spatial, id=NULL, method=c("contiguity","distance","knn"),
                          contiguity=c("queen","rook"), style=c("W","B","raw"),
                          distance=NULL, k=4L, symmetrize=c("union","mutual","none")) {
  style<-match.arg(style); method<-match.arg(method); contiguity<-match.arg(contiguity);symmetrize<-match.arg(symmetrize)
  if(is.matrix(spatial) || inherits(spatial,"Matrix")) {
    w <- .matrix(spatial,"weights")
  } else {
    if(!inherits(spatial,"sf")) stop("spatial must be sf or an ID-labelled weight matrix.")
    ids<-if(is.null(id)) .ids(rownames(spatial),nrow(spatial)) else {
      if(length(id)!=1L || !id %in% names(spatial)) stop("id must name a spatial ID column.")
      .ids(spatial[[id]],nrow(spatial))
    }
    if(any(sf::st_is_empty(spatial)) || anyNA(sf::st_is_valid(spatial)) || any(!sf::st_is_valid(spatial))) stop("Empty or invalid geometry; repair it explicitly before analysis.")
    types<-as.character(sf::st_geometry_type(spatial))
    if(method=="contiguity") {
      if(any(!types %in% c("POLYGON","MULTIPOLYGON"))) stop("Queen/rook contiguity requires polygons.")
      nb<-suppressWarnings(spdep::poly2nb(spatial,queen=contiguity=="queen",row.names=ids))
      w<-spdep::nb2mat(nb,style="B",zero.policy=TRUE)
    } else {
      if(any(types!="POINT")) stop("Distance/knn requires POINT geometry; choose polygon representative points explicitly.")
      if(is.na(sf::st_crs(spatial))) stop("Distance/knn requires a known CRS.")
      d<-sf::st_distance(spatial); units<-attr(d,"units"); d<-matrix(as.numeric(d),nrow=nrow(spatial));diag(d)<-Inf
      if(method=="distance") {
        if(length(distance)!=1L || !is.numeric(distance) || !is.finite(distance) || distance<=0) stop("distance must be positive, in st_distance units (metres for longitude/latitude).")
        w<-1*(d<=distance)
      } else {
        k<-.integer(k,"k");if(k>=nrow(d)) stop("k must be smaller than the number of regions.")
        w<-matrix(0,nrow(d),ncol(d))
        for(i in seq_len(nrow(d))) w[i,order(d[i,],ids)[seq_len(k)]]<-1
        if(symmetrize=="union") w<-pmax(w,t(w))
        if(symmetrize=="mutual") w<-pmin(w,t(w))
      }
    }
    dimnames(w)<-list(ids,ids)
  }
  diag(w)<-0
  if(any(rowSums(w)==0)) stop("Isolated regions: ",paste(rownames(w)[rowSums(w)==0],collapse=", "),". Change the neighbour definition; no rows were dropped.")
  if(style=="B") w<-1*(w>0)
  if(style=="W") w<-w/rowSums(w)
  attr(w,"settings")<-list(method=if(is.matrix(spatial)) "supplied" else method,contiguity=contiguity,style=style,distance=distance,k=k,symmetrize=symmetrize)
  w
}
mlsas_similarity <- function(x, proximity=c("path","terminal"), ntree=1000L,
                             mtry=NULL, nodesize=1L, seed=NULL, workers=1L,
                             verbose=TRUE, progress=interactive(), synthetic=NULL) {
  start<-proc.time()[3];x<-.attributes(x);proximity<-match.arg(proximity)
  ntree<-.integer(ntree,"ntree");nodesize<-.integer(nodesize,"nodesize");workers<-.integer(workers,"workers")
  if(is.null(mtry)) mtry<-max(1L,floor(sqrt(ncol(x))))
  mtry<-.integer(mtry,"mtry");if(mtry>ncol(x)) stop("mtry exceeds number of attributes.")
  restore<-.seed(seed);on.exit(restore(),add=TRUE)
  n<-nrow(x);ids<-.ids(rownames(x),n)
  if(verbose) message("Learning attribute similarity: ",n," observations, ",ntree," trees. This may take several minutes.\n[1/3] Generating synthetic data...")
  if(is.null(synthetic)) synthetic<-as.data.frame(lapply(x,function(z) sample(z,replace=TRUE))) else {
    synthetic<-.attributes(synthetic)
    if(!identical(dim(synthetic),dim(x)) || !identical(names(synthetic),names(x)) || !identical(lapply(synthetic,class),lapply(x,class)) || !identical(lapply(synthetic,levels),lapply(x,levels))) stop("synthetic must match attribute dimensions, types and levels.")
  }
  all<-rbind(x,synthetic)
  if(verbose) message("[2/3] Fitting random forest... running")
  rf<-randomForest::randomForest(x=all,y=factor(rep(c("real","synthetic"),each=n)),ntree=ntree,mtry=mtry,nodesize=nodesize)
  if(verbose) message("[3/3] Computing ",proximity," proximity...")
  # Fixed groups preserve the paper empirical accumulation order, independently of workers.
  groups<-split(seq_len(ntree),ceiling(seq_len(ntree)/max(1L,ceiling(ntree/96L))))
  calculate<-function(g,rf,all,n,proximity) {
    ans<-matrix(0,n,n)
    for(t in g) {
      tree<-randomForest::getTree(rf,k=t,labelVar=FALSE)
      paths<-.extract_real_tree_paths_optimized(tree,all,n)
      if(proximity=="path") ans<-ans+.path_jaccard_sparse_optimized(paths,nrow(tree)) else {
        terminal<-vapply(paths,function(z) utils::tail(z,1L),numeric(1));ans<-ans+outer(terminal,terminal,"==")
      }
    }
    ans
  }
  pb<-.progress(ntree,progress);on.exit(pb$close(),add=TRUE)
  s<-matrix(0,n,n);done<-0L
  if(workers>1L) {cl<-parallel::makePSOCKcluster(min(workers,length(groups)));on.exit(parallel::stopCluster(cl),add=TRUE);parallel::clusterCall(cl,function(paths) .libPaths(paths),.libPaths())}
  for(first in seq.int(1L,length(groups),by=workers)) {
    gs<-groups[first:min(length(groups),first+workers-1L)]
    results<-if(workers==1L) lapply(gs,calculate,rf=rf,all=all,n=n,proximity=proximity) else parallel::parLapply(cl,gs,calculate,rf=rf,all=all,n=n,proximity=proximity)
    for(j in seq_along(results)) {s<-s+results[[j]];done<-done+length(gs[[j]]);pb$tick(done)}
  }
  s<-s/ntree;dimnames(s)<-list(ids,ids)
  attr(s,"settings")<-list(proximity=proximity,ntree=ntree,mtry=mtry,nodesize=nodesize,seed=seed,workers=workers,engine=as.character(utils::packageVersion("randomForest")),elapsed=unname(proc.time()[3]-start))
  if(verbose) message("Similarity matrix computed in ",round(proc.time()[3]-start,2)," seconds.")
  s
}
mlsas_stat <- function(similarity, weights) {
  s<-.matrix(similarity,"similarity",TRUE);w<-.matrix(weights,"weights")
  if(!setequal(rownames(s),rownames(w))) stop("Region IDs in similarity and weights do not match.")
  w<-w[rownames(s),rownames(s),drop=FALSE]
  if(any(rowSums(w)==0)) stop("Isolated regions are not supported.")
  n<-nrow(s);P<-n*(n-1)*w/sum(w);Q<-s/sum(s);local<-n*rowSums(P*Q)
  structure(list(global=sum(P*Q),local=local,P=P,Q=Q,ids=rownames(s),settings=list(similarity=attr(similarity,"settings"),weights=attr(weights,"settings"))),class="mlsas_stat")
}
