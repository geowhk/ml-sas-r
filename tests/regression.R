library(mlsas)
fail <- function(expr) stopifnot(inherits(tryCatch({force(expr);NULL},error=function(e)e),"error"))
near <- function(a,b,tol=1e-12) stopifnot(isTRUE(all.equal(as.numeric(a),as.numeric(b),tolerance=tol)))
d <- mlsas_example()
stopifnot(nrow(d$data)==36L, inherits(d$data,"sf"),is.ordered(d$x$ordered))
w <- d$weights; near(rowSums(w),rep(1,36))
r <- mlsas_weights(d$data,id="region_id",contiguity="rook")
stopifnot(sum(w>0)>sum(r>0))
set.seed(912);old<-.Random.seed
s <- mlsas_similarity(d$x,ntree=8,seed=7,verbose=FALSE,progress=FALSE)
stopifnot(identical(old,.Random.seed));near(s,t(s));near(diag(s),rep(1,36))
s2 <- mlsas_similarity(d$x,ntree=8,seed=7,workers=2,verbose=FALSE,progress=FALSE)
near(s,s2,0)
t <- mlsas_similarity(d$x,ntree=8,seed=7,proximity="terminal",verbose=FALSE,progress=FALSE)
near(diag(t),rep(1,36));stopifnot(all(s>=t-1e-12))
z<-mlsas_stat(s,w);near(mean(z$local),z$global)
fail(mlsas_stat(s,w[-1,-1]));fail(mlsas_similarity(transform(d$x,x1=NA_real_),verbose=FALSE))
fail(mlsas_weights(matrix(0,4,4)))
# Exact enumeration: independently compute all arrangements on four regions.
perms<-function(x) if(length(x)==1L) matrix(x,1) else do.call(cbind,lapply(seq_along(x),function(i) rbind(x[i],perms(x[-i]))))
pi<-perms(1:4)
S<-matrix(c(1,.8,.2,.3,.8,1,.5,.1,.2,.5,1,.6,.3,.1,.6,1),4)
W<-matrix(c(0,1,0,1,1,0,1,0,0,1,0,1,1,0,1,0),4)
dimnames(S)<-dimnames(W)<-list(letters[1:4],letters[1:4]);W<-mlsas_weights(W)
o<-mlsas_stat(S,W)
g<-mlsas_global_test(o,permutations=pi,keep=TRUE,verbose=FALSE,progress=FALSE)
manual<-apply(pi,2,function(p) sum(o$P*o$Q[p,p]))
near(manual,g$permutations);near(mean(manual),1)
near(g$table$p_high,(sum(manual>=o$global)+1)/25)
for(scheme in c("conditional","total")) {
 l<-mlsas_local_test(o,randomization=scheme,permutations=pi,keep=TRUE,verbose=FALSE,progress=FALSE)
 manual<-sapply(seq_len(ncol(pi)),function(j) sapply(1:4,function(i) {
   p<-pi[,j]
   if(scheme=="conditional") {where<-which(p==i);p[where]<-p[i];p[i]<-i}
   4*sum(o$P[i,]*o$Q[p[i],p])
 }))
 near(l$permutations,manual)
 near(l$table$permutation_mean,rowMeans(manual))
 near(l$table$permutation_sd,apply(manual,1,sd))
 near(l$table$p_adjusted,p.adjust(l$table$p_value,"BH"))
}
one<-mlsas_local_test(o,nperm=1,seed=1,verbose=FALSE,progress=FALSE);stopifnot(all(is.na(one$table$permutation_sd)))
fail(mlsas_local_test(o,permutations=matrix(1,4,2),verbose=FALSE))
fit<-mlsas(d$data,variables=d$variables,id=d$id,ntree=8,nperm=19,seed=12,verbose=FALSE,progress=FALSE)
fit2<-mlsas(d$attributes,variables=d$variables,id=d$id,spatial=d$spatial[36:1,],ntree=8,nperm=19,seed=12,verbose=FALSE,progress=FALSE)
fit3<-mlsas(d$attributes,variables=d$variables,id=d$id,weights=d$weights,ntree=8,nperm=19,seed=12,verbose=FALSE,progress=FALSE)
near(fit$similarity,fit2$similarity,0);near(fit$similarity,fit3$similarity,0)
near(fit$local$table$p_value,fit2$local$table$p_value,0)
fail(mlsas(d$attributes,d$variables,d$id,spatial=d$spatial[-1,],verbose=FALSE))
fail(mlsas(d$data,d$variables,d$id,weights=d$weights,verbose=FALSE))
# No state mutation, no automatic row deletion; basic point-neighbour options.
p<-sf::st_as_sf(data.frame(id=letters[1:4],x=c(0,1,2,3),y=c(0,0,0,0)),coords=c("x","y"),crs=3857)
for(method in c("distance","knn")) {
 wp<-mlsas_weights(p,id="id",method=method,distance=1.1,k=1)
 near(rowSums(wp),rep(1,4))
}
pdf(file=tempfile(fileext=".pdf"));plot(fit);plot(fit$local);dev.off()
cat("PASS: matrix identities, exact total/conditional enumeration, input routes, spatial options, serial/parallel similarity, RNG preservation and plotting.\n")

# Tail choices and all documented p.adjust methods use the same raw counts.
for(alt in c("greater","less","two.sided")) for(adj in c("BH","BY","holm","bonferroni","none")) {
 a<-mlsas_local_test(o,alternative=alt,p_adjust=adj,permutations=pi,verbose=FALSE,progress=FALSE)
 expected<-switch(alt,greater=a$table$p_high,less=a$table$p_low,two.sided=pmin(1,2*pmin(a$table$p_high,a$table$p_low)))
 near(a$table$p_value,expected);near(a$table$p_adjusted,p.adjust(expected,adj))
}
for(sym in c("union","mutual","none")) {
 wp<-mlsas_weights(p,id="id",method="knn",k=3,symmetrize=sym,style="B")
 stopifnot(all(wp %in% c(0,1)))
}
raw<-mlsas_weights(W,style="raw");near(raw,W)
fail(mlsas_weights(p,id="id",method="distance",distance=0.1))
fail(mlsas_similarity(data.frame(a=factor(as.character(1:32))),ntree=1,verbose=FALSE))
# Fitted leaf co-membership is independently reconstructed from the forest.
set.seed(7);synthetic<-as.data.frame(lapply(d$x,function(z) sample(z,replace=TRUE)))
rf<-randomForest::randomForest(x=rbind(d$x,synthetic),y=factor(rep(c("real","synthetic"),each=36)),ntree=8,mtry=2,nodesize=1)
leaf<-attr(predict(rf,d$x,nodes=TRUE),"nodes")
direct<-Reduce("+",lapply(1:8,function(i) outer(leaf[,i],leaf[,i],"==")))/8
near(t,direct,0)
cat("PASS: alternative tails, adjustment options, weight transforms, isolation/factor guards and independent terminal proximity.\n")
