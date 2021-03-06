#' Mock file
#' 
#' @export
#' @param path (character) a file path. required
#' @param payload (character) string to be written to the file given 
#' at `path` parameter. required
#' @return a list with S3 class `mock_file`
#' @examples
#' mock_file(path = tempfile(), payload = "{\"foo\": \"bar\"}")
mock_file <- function(path, payload) {
  assert(path, "character")
  assert(payload, c("character", "json"))
  structure(list(path = path, payload = payload), class = "mock_file")
}
#' @export
print.mock_file <- function(x, ...) {
  cat("<mock file>", sep = "\n")
  cat(paste0(" path: ", x$path), sep = "\n")
  cat(paste0(" payload: ", substring(x$payload, 1, 80)), sep = "\n")
}
