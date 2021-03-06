#' Mocking writing to disk
#' 
#' @name mocking-disk-writing
#' @examples \dontrun{
#' # enable mocking
#' enable()
#' 
#' # Write to a file before mocked request
#' 
#' # crul
#' library(crul)
#' ## make a temp file
#' f <- tempfile(fileext = ".json")
#' ## write something to the file
#' cat("{\"hello\":\"world\"}\n", file = f)
#' readLines(f)
#' ## make the stub
#' stub_request("get", "https://httpbin.org/get") %>% 
#'   to_return(body = file(f))
#' ## make a request
#' (out <- HttpClient$new("https://httpbin.org/get")$get(disk = f))
#' out$content
#' readLines(out$content)
#' 
#' # httr
#' library(httr)
#' ## make a temp file
#' f <- tempfile(fileext = ".json")
#' ## write something to the file
#' cat("{\"hello\":\"world\"}\n", file = f)
#' readLines(f)
#' ## make the stub
#' stub_request("get", "https://httpbin.org/get") %>% 
#'   to_return(body = file(f), 
#'    headers = list('content-type' = "application/json"))
#' ## make a request
#' ## with httr, you must set overwrite=TRUE or you'll get an errror
#' out <- GET("https://httpbin.org/get", write_disk(f, overwrite=TRUE))
#' out
#' out$content
#' content(out, "text", encoding = "UTF-8")
#' 
#' 
#' # Use mock_file to have webmockr handle file and contents
#' 
#' # crul
#' library(crul)
#' f <- tempfile(fileext = ".json")
#' ## make the stub
#' stub_request("get", "https://httpbin.org/get") %>% 
#'   to_return(body = mock_file(f, "{\"hello\":\"mars\"}\n"))
#' ## make a request
#' (out <- crul::HttpClient$new("https://httpbin.org/get")$get(disk = f))
#' out$content
#' readLines(out$content)
#' 
#' # httr
#' library(httr)
#' ## make a temp file
#' f <- tempfile(fileext = ".json")
#' ## make the stub
#' stub_request("get", "https://httpbin.org/get") %>% 
#'   to_return(
#'     body = mock_file(path = f, payload = "{\"foo\": \"bar\"}"),
#'     headers = list('content-type' = "application/json")
#'   )
#' ## make a request
#' out <- GET("https://httpbin.org/get", write_disk(f))
#' out
#' ## view stubbed file content
#' out$content
#' readLines(out$content)
#' content(out, "text", encoding = "UTF-8")
#' 
#' # disable mocking
#' disable()
#' }
NULL
