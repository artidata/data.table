# all non-exported / unused internal (utility) functions

# R 3.5.0 made isTRUE longer but more efficient :
#   `is.logical(x) && length(x)==1L && !is.na(x) && x`
# Before R 3.5.0, isTRUE was defined as simply:
#   identical(TRUE,x)
# See PR#3421 for timings.
# It was changed in R so that isTRUE(c(a=TRUE)) returned TRUE: https://github.com/wch/r-source/commit/828997ac6ecfb73aaa0aae9d1d0584a4ffc50881#diff-b41e3f9f1d389bb6f7a842cd5a3308b8
if (base::getRversion() < "3.5.0") {
  isTRUE  = function(x) is.logical(x) && length(x)==1L && !is.na(x) && x    # backport R's new implementation of isTRUE
  isFALSE = function(x) is.logical(x) && length(x)==1L && !is.na(x) && !x   # backport isFALSE that was added in R 3.5.0
}
isTRUEorNA    = function(x) is.logical(x) && length(x)==1L && (is.na(x) || x)
isTRUEorFALSE = function(x) is.logical(x) && length(x)==1L && !is.na(x)

if (base::getRversion() < "3.2.0") {  # Apr 2015
  isNamespaceLoaded = function(x) x %chin% loadedNamespaces()
}

# which.first
which.first = function(x)
{
  if (!is.logical(x)) {
    stop("x not boolean")
  }
  match(TRUE, x)
}

# which.last
which.last = function(x)
{
  if (!is.logical(x)) {
    stop("x not boolean")
  }
  length(x) - match(TRUE, rev(x)) + 1L
}

require_bit64_if_needed = function(DT) {
  # called in fread and print.data.table
  if (!isNamespaceLoaded("bit64") && any(sapply(DT,inherits,"integer64"))) {
    # nocov start
    # a test was attempted to cover the requireNamespace() by using unloadNamespace() first, but that fails when nanotime is loaded because nanotime also uses bit64
    if (!requireNamespace("bit64",quietly=TRUE)) {
      warning("Some columns are type 'integer64' but package bit64 is not installed. Those columns will print as strange looking floating point data. There is no need to reload the data. Simply install.packages('bit64') to obtain the integer64 print method and print the data again.")
    }
    # nocov end
  }
}

# vapply for return value character(1)
vapply_1c = function (x, fun, ..., use.names = TRUE) {
  vapply(X = x, FUN = fun, ..., FUN.VALUE = NA_character_, USE.NAMES = use.names)
}

# vapply for return value logical(1)
vapply_1b = function (x, fun, ..., use.names = TRUE) {
  vapply(X = x, FUN = fun, ..., FUN.VALUE = NA, USE.NAMES = use.names)
}

# vapply for return value integer(1)
vapply_1i = function (x, fun, ..., use.names = TRUE) {
  vapply(X = x, FUN = fun, ..., FUN.VALUE = NA_integer_, USE.NAMES = use.names)
}

more = function(f) system(paste("more",f))    # nocov  (just a dev helper)

# helper used to auto-name columns in data.table(x,y) as c("x","y"), CJ(x,y) and similar
# naming of unnested matrices still handled by data.table()
name_dots = function(...) {
  dot_sub = as.list(substitute(list(...)))[-1L]
  vnames = names(dot_sub)
  if (is.null(vnames)) {
    vnames = rep.int("", length(dot_sub))
    novname = rep.int(TRUE, length(dot_sub))
  } else {
    vnames[is.na(vnames)] = ""
    if (any(vnames==".SD")) stop("A column may not be called .SD. That has special meaning.")
    novname = vnames==""
  }
  for (i in which(novname)) {
    if ((tmp <- deparse(dot_sub[[i]])[1L]) == make.names(tmp))
      vnames[i] = tmp
  }
  still_empty = vnames==""
  if (any(still_empty)) vnames[still_empty] = paste0("V", which(still_empty))
  list(vnames=vnames, novname=novname)
}

# convert a vector like c(1, 4, 3, 2) into a string like [1, 4, 3, 2]
#   (common aggregation method for error messages)
brackify = function(x) {
  # arbitrary cutoff
  if (length(x) > 10L) x = c(x[1:10], '...')
  sprintf('[%s]', paste(x, collapse = ', '))
}

# patterns done via NSE in melt.data.table and .SDcols in `[.data.table`
do_patterns = function(pat_sub, all_cols) {
  # received as substitute(patterns(...))
  pat_sub = as.list(pat_sub)[-1L]
  # identify cols = argument if present
  idx = which(names(pat_sub) == "cols")
  if (length(idx)) {
    cols = eval(pat_sub[["cols"]], parent.frame(2L))
    pat_sub = pat_sub[-idx]
  } else cols = all_cols
  pats = lapply(pat_sub, eval, parent.frame(2L))
  matched = patterns(pats, cols=cols)
  # replace with lengths when R 3.2.0 dependency arrives
  if (length(idx <- which(sapply(matched, length) == 0L)))
    stop('Pattern', if (length(idx) > 1L) 's', ' not found: [',
         paste(pats[idx], collapse = ', '), ']')

  return(matched)
}
