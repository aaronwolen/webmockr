#' @title RequestSignature
#' @description General purpose request signature builder
#' @export
#' @examples
#' # make request signature
#' x <- RequestSignature$new(method = "get", uri = "https:/httpbin.org/get")
#' # method
#' x$method
#' # uri
#' x$uri
#' # request signature to string
#' x$to_s()
#'
#' # headers
#' w <- RequestSignature$new(
#'   method = "get",
#'   uri = "https:/httpbin.org/get",
#'   options = list(headers = list(`User-Agent` = "foobar", stuff = "things"))
#' )
#' w
#' w$headers
#' w$to_s()
#'
#' # headers and body
#' bb <- RequestSignature$new(
#'   method = "get",
#'   uri = "https:/httpbin.org/get",
#'   options = list(
#'     headers = list(`User-Agent` = "foobar", stuff = "things"),
#'     body = list(a = "tables")
#'   )
#' )
#' bb
#' bb$headers
#' bb$body
#' bb$to_s()
#' 
#' # with disk path
#' f <- tempfile()
#' bb <- RequestSignature$new(
#'   method = "get",
#'   uri = "https:/httpbin.org/get",
#'   options = list(disk = f)
#' )
#' bb
#' bb$disk
#' bb$to_s()
RequestSignature <- R6::R6Class(
  'RequestSignature',
  public = list(
    #' @field method (character) an http method
    method = NULL,
    #' @field uri (character) a uri
    uri = NULL,
    #' @field body (various) request body
    body = NULL,
    #' @field headers (list) named list of headers
    headers = NULL,
    #' @field proxies (list) proxies as a named list
    proxies = NULL,
    #' @field auth (list) authentication details, as a named list
    auth = NULL,
    #' @field url internal use
    url = NULL,
    #' @field disk (character) if writing to disk, the path
    disk = NULL,

    #' @description Create a new `RequestSignature` object
    #' @param method the HTTP method (any, head, options, get, post, put,
    #' patch, trace, or delete). "any" matches any HTTP method. required.
    #' @param uri (character) request URI. required.
    #' @param options (list) options. optional. See Details.
    #' @return A new `RequestSignature` object
    initialize = function(method, uri, options = list()) {
      verb <- match.arg(tolower(method), http_verbs)
      self$method <- verb
      self$uri <- uri
      self$url$url <- uri
      if (length(options)) private$assign_options(options)
    },

    #' @description print method for the `RequestSignature` class
    #' @param x self
    #' @param ... ignored
    print = function() {
      cat("<RequestSignature> ", sep = "\n")
      cat(paste0("  method: ", toupper(self$method)), sep = "\n")
      cat(paste0("  uri: ", self$uri), sep = "\n")
      if (!is.null(self$body)) {
        cat("  body: ", sep = "\n")
        if (inherits(self$body, "form_file")) {
          cat(paste0("     ",
              sprintf("type=%s; path=%s", self$body$type, self$body$path)),
              sep = "\n")
        } else {
          cat_foo(self$body)
        }
      }
      if (!is.null(self$headers)) {
        cat("  headers: ", sep = "\n")
        cat_foo(self$headers)
      }
      if (!is.null(self$proxies)) {
        cat("  proxies: ", sep = "\n")
        cat_foo(self$proxies)
      }
      if (!is.null(self$auth)) {
        cat("  auth: ", sep = "\n")
        cat_foo(self$auth)
      }
      if (!is.null(self$disk)) {
        cat(paste0("  disk: ", self$disk), sep = "\n")
      }
    },

    #' @description Request signature to a string
    #' @return a character string representation of the request signature
    to_s = function() {
      gsub("^\\s+|\\s+$", "", paste(
        paste0(toupper(self$method), ": "),
        self$uri,
        if (!is.null(self$body) && length(self$body)) {
          paste0(" with body ", to_string(self$body))
        },
        if (!is.null(self$headers) && length(self$headers)) {
          paste0(
            " with headers ",
            sprintf("{%s}",
                    paste(names(self$headers),
                          unlist(unname(self$headers)), sep = ": ",
                          collapse = ", "))
          )
        }
      ))
    }
  ),

  private = list(
    assign_options = function(options) {
      if ('body' %in% names(options)) {
        if (!is.null(options$body) && length(options)) {
          self$body <- options$body
        }
      }
      if ('headers' %in% names(options)) {
        if (!is.null(options$headers) && length(options)) {
          self$headers <- options$headers
        }
      }
      if ('proxies' %in% names(options)) {
        if (!is.null(options$proxies) && length(options)) {
          self$proxies <- options$proxies
        }
      }
      if ('auth' %in% names(options)) {
        if (!is.null(options$auth) && length(options)) {
          self$auth <- options$auth
        }
      }
      if ('disk' %in% names(options)) {
        if (!is.null(options$disk) && length(options)) {
          self$disk <- options$disk
        }
      }
    }
  )
)

cat_foo <- function(x) {
  cat(paste0("     ",
             paste0(paste(names(x), x, sep = ": "),
                    collapse = "\n     ")), sep = "\n")
}

to_string <- function(x) {
  if (inherits(x, "list") && all(nchar(names(x)) > 0)) {
    tmp <- paste0(paste(names(x), x, sep = ": "), collapse = ", ")
  } else if (inherits(x, "list") && any(nchar(names(x)) == 0)) {
    tmp <- paste0(paste(names(x), x, sep = ": "), collapse = ", ")
  } else if (inherits(x, "form_file")) {
    tmp <- sprintf("type=%s; path=%s", x$type, x$path)
  } else {
    tmp <- paste0(x, collapse = ", ")
  }
  return(sprintf("{%s}", tmp))
}
