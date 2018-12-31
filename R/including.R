#' partially match
#' 
#' @export
#' @param x input, a list
#' @examples
#' including(list("foo"))
#' including(list(foo = "bar"))
#' # just keys by setting values as NULL
#' including(list(foo = NULL, bar = NULL))
#' 
#' # in a stub
#' req <- stub_request("get", "https://httpbin.org/get")
#' wi_th(req, body = list(foo = "bar"))
#' wi_th(req, body = including(list(foo = "bar")))
including <- function(x) {
  attr(x, "partial_match") <- TRUE
  return(x)
}
