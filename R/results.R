mlsas_example <- function(type=c("mixed","continuous")) {
  type<-match.arg(type)
  grid<-expand.grid(col=1:6,row=1:6);ids<-sprintf("area_%02d",seq_len(nrow(grid)))
  attrs<-data.frame(region_id=ids,x1=sin(grid$col)+grid$row/6,x2=cos(grid$row)+grid$col/6)
  if(type=="mixed") {attrs$category<-factor(ifelse(grid$col<=3,"A","B"));attrs$ordered<-ordered(ifelse(grid$row<=2,"low",ifelse(grid$row<=4,"medium","high")),levels=c("low","medium","high"))}
  polygons<-lapply(seq_len(nrow(grid)),function(i) {x<-grid$col[i];y<-grid$row[i];sf::st_polygon(list(matrix(c(x,y,x+1,y,x+1,y+1,x,y+1,x,y),ncol=2,byrow=TRUE)))})
  regions<-sf::st_sf(attrs,geometry=sf::st_sfc(polygons,crs=3857))
  weights<-mlsas_weights(regions,id="region_id")
  x<-attrs[,-1,drop=FALSE];rownames(x)<-ids
  list(data=regions,attributes=attrs,spatial=regions[,"region_id",drop=FALSE],x=x,weights=weights,variables=names(x),id="region_id")
}
print.mlsas_stat <- function(x,...) {cat("ML-SAS:",length(x$ids),"regions; global statistic =",format(x$global),"\n");invisible(x)}
print.mlsas_test <- function(x,...) {print(x$table,...);invisible(x)}
print.mlsas_fit <- function(x,...) {print(x$statistic);print(x$global);print(table(x$local$table$classification));invisible(x)}
summary.mlsas_fit <- function(object,...) list(global=object$global$table,local_classification=table(object$local$table$classification),settings=object$settings,similarity=object$statistic$settings$similarity,inference=object$local$settings)
summary.mlsas_test <- function(object,...) list(table=object$table,settings=object$settings)
as.data.frame.mlsas_test <- function(x,row.names=NULL,optional=FALSE,...) as.data.frame(x$table,row.names=row.names,optional=optional,...)
plot.mlsas_test <- function(x,...) {
  graphics::plot(seq_len(nrow(x$table)),x$table$statistic,xlab="Region index",ylab="ML-SAS",...)
  invisible(x)
}
plot.mlsas_fit <- function(x,...) {
  if(is.null(x$spatial)) return(plot(x$local,...))
  levels<-c("Not significant","Similarity cluster","Dissimilarity/outlier")
  cols<-c("grey85","#2166ac","#b2182b")
  graphics::plot(sf::st_geometry(x$spatial),col=cols[match(x$local$table$classification,levels)],...)
  graphics::legend("bottomleft",legend=levels,fill=cols,bty="n",cex=0.7)
  invisible(x)
}
