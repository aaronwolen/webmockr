http_verbs <- c("any", "get", "post", "put", "patch", "head", "delete")

cc <- function(x) Filter(Negate(is.null), x)

is_nested <- function(x) {
  stopifnot(is.list(x))
  for (i in x) {
    if (is.list(i)) return(TRUE)
  }
  return(FALSE)
}

col_l <- function(w) paste(names(w), unname(unlist(w)), sep = "=")

hdl_nested <- function(x) {
  if (!is_nested(x)) col_l(x)
}

subs <- function(x, n) {
  unname(vapply(x, function(w) {
    w <- as.character(w)
    if (nchar(w) > n) paste0(substring(w, 1, n), "...") else w
  }, ""))
}

l2c <- function(w) paste(names(w), as.character(w), sep = " = ", collapse = "")

hdl_lst <- function(x) {
  if (is.null(x) || length(x) == 0) return("")
  if (is.raw(x)) return(paste0("raw bytes, length: ", length(x)))
  if (inherits(x, "form_file"))
    return(sprintf("crul::upload(\"%s\", type=\"%s\")", x$path, x$type))
  if (inherits(x, "mock_file")) return(paste0("mock file, path: ", x$path))
  if (inherits(x, "list")) {
    if (is_nested(x)) {
      # substring(l2c(x), 1, 80)
      subs(l2c(x), 80)
    } else {
      txt <- paste(names(x), subs(unname(unlist(x)), 20), sep = "=",
        collapse = ", ")
      substring(txt, 1, 80)
    }
  } else {
    x
  }
}

hdl_lst2 <- function(x) {
  if (is.null(x) || length(x) == 0) return("")
  if (is.raw(x)) return(rawToChar(x))
  if (inherits(x, "form_file"))
    return(sprintf("crul::upload(\"%s\", \"%s\")", x$path, x$type))
  if (inherits(x, "list")) {
    if (any(vapply(x, function(z) inherits(z, "form_file"), logical(1))))
      for (i in seq_along(x)) x[[i]] <- sprintf("crul::upload(\"%s\", \"%s\")", x[[i]]$path, x[[i]]$type)
    out <- vector(mode = "character", length = length(x))
    for (i in seq_along(x)) {
      targ <- x[[i]]
      out[[i]] <- paste(names(x)[i], switch(
        class(targ)[1L],
        character = if (grepl("upload", targ)) targ else sprintf('\"%s\"', targ),
        list = sprintf("list(%s)", hdl_lst2(targ)),
        targ
      ), sep = "=")
    }
    return(paste(out, collapse = ", "))
  } else {
    # FIXME: dumping ground, just spit out whatever and hope for the best
    return(x)
  }
}

parseurl <- function(x) {
  tmp <- urltools::url_parse(x)
  tmp <- as.list(tmp)
  if (!is.na(tmp$parameter)) {
    tmp$parameter <- sapply(strsplit(tmp$parameter, "&")[[1]], function(z) {
      zz <- strsplit(z, split = "=")[[1]]
      as.list(stats::setNames(zz[2], zz[1]))
    }, USE.NAMES = FALSE)
  }
  tmp
}

url_builder <- function(uri, args = NULL) {
  if (is.null(args)) return(uri)
  paste0(uri, "?", paste(names(args), args, sep = "=", collapse = "&"))
}

`%||%` <- function(x, y) {
  if (
    is.null(x) || length(x) == 0 || all(nchar(x) == 0) || all(is.na(x))
  ) y else x
}

# tryCatch version of above
`%|s|%` <- function(x, y) {
  z <- tryCatch(x)
  if (inherits(z, "error")) return(y)
  if (
    is.null(z) || length(z) == 0 || all(nchar(z) == 0) || all(is.na(z))
  ) y else x
}

`!!` <- function(x) if (is.null(x) || is.na(x)) FALSE else TRUE

assert <- function(x, y) {
  if (!is.null(x)) {
    if (!inherits(x, y)) {
      stop(deparse(substitute(x)), " must be of class ",
           paste0(y, collapse = ", "), call. = FALSE)
    }
  }
}

assert_gte <- function(x, y) {
  if (!x >= y) {
    stop(sprintf("%s must be greater than or equal to %s",
      deparse(substitute(x)), y), call. = FALSE)
  }
}

crul_head_parse <- function(z) {
  if (grepl("HTTP\\/", z)) {
    list(status = z)
  } else {
    ff <- regexec("^([^:]*):\\s*(.*)$", z)
    xx <- regmatches(z, ff)[[1]]
    as.list(stats::setNames(xx[[3]], tolower(xx[[2]])))
  }
}

crul_headers_parse <- function(x) do.call("c", lapply(x, crul_head_parse))

#' execute a curl request
#' @export
#' @keywords internal
#' @param x an object
#' @return a curl response
webmockr_crul_fetch <- function(x) {
  if (is.null(x$disk) && is.null(x$stream)) {
    curl::curl_fetch_memory(x$url$url, handle = x$url$handle)
  }
  else if (!is.null(x$disk)) {
    curl::curl_fetch_disk(x$url$url, x$disk, handle = x$url$handle)
  }
  else {
    curl::curl_fetch_stream(x$url$url, x$stream, handle = x$url$handle)
  }
}

# modified from purrr:::has_names
along_rep <- function(x, y) rep(y, length.out = length(x))
hz_namez <- function(x) {
  nms <- names(x)
  if (is.null(nms)) {
    along_rep(x, FALSE)
  } else {
    !(is.na(nms) | nms == "")
  }
}

# check for a package
check_for_pkg <- function(x) {
  if (!requireNamespace(x, quietly = TRUE)) {
    stop(sprintf("Please install '%s'", x), call. = FALSE)
  } else {
   invisible(TRUE)
  }
}

# lower case names in a list, return that list
names_to_lower <- function(x) {
  names(x) <- tolower(names(x))
  return(x)
}

as_character <- function(x) {
  stopifnot(is.list(x))
  lapply(x, as.character)
}

last <- function(x) {
  if (length(x) == 0) return(list())
  x[[length(x)]]
}


vcr_loaded <- function() {
  "package:vcr" %in% search()
}

# check whether a cassette is inserted without assuming vcr is installed
vcr_cassette_inserted <- function() {
  if (vcr_loaded()) {
    return(length(vcr::current_cassette()) > 0)
  }
  return(FALSE)  
}
