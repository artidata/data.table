shift = function(x, n=1L, fill=NA, type=c("lag", "lead", "shift"), give.names=FALSE) {
  type = match.arg(type)
  stopifnot(is.numeric(n))
  ans = .Call(Cshift, x, as.integer(n), fill, type)
  if (give.names && is.list(ans)) {
    if (is.null(names(x))) {
      xsub = substitute(x)
      if (is.atomic(x) && is.name(xsub)) nx = deparse(xsub, 500L)
      else nx = paste0("V", if (is.atomic(x)) 1L else seq_along(x))
    }
    else nx = names(x)
    if (type!="shift") {
      # flip type for negative n, #3223
      neg = (n<0L)
      if (type=="lead") neg[ n==0L ] = TRUE   # lead_0 should be named lag_0 for consistency
      if (any(neg)) {
        type = rep(type,length(n))
        type[neg] = if (type[1L]=="lead") "lag" else "lead"
        n[neg] = -n[neg]
      }
    }
    setattr(ans, "names",  paste(rep(nx,each=length(n)), type, n, sep="_"))
  }
  ans
}

nafill = function(x, type=c("const","locf","nocb"), fill=NA, verbose=getOption("datatable.verbose")) {
  type = match.arg(type)
  if (type!="const" && !missing(fill))
    warning("argument 'fill' ignored, only make sense for type='const'")
  .Call(CnafillR, x, type, fill, FALSE, NULL, verbose)
}

setnafill = function(x, type=c("const","locf","nocb"), fill=NA, cols=seq_along(x), verbose=getOption("datatable.verbose")) {
  type = match.arg(type)
  if (type!="const" && !missing(fill))
    warning("argument 'fill' ignored, only make sense for type='const'")
  invisible(.Call(CnafillR, x, type, fill, TRUE, cols, verbose))
}

colnamesInt = function(x, cols) {
  .Call(CcolnamesInt, x, cols)
}
