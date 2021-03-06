# Take a sketch R file as input and extract the resources links as
# provided by the user with the '#!' header.
assets <- function(file) {
    file_lines <- readLines(file)
    keep <- purrr::map_lgl(file_lines, is_src_line)

    src_lines <- file_lines[keep] %>%
        purrr::map_chr(extract_src)

    r_indicator <- src_lines %>%
        purrr::map_lgl(is_r_script)

    top_level_assets <- src_lines %>%
        purrr::map(convert_src) %>%
        sort_list(r_indicator, c("body", "head"))
    low_level_assets <- purrr::map(src_lines[r_indicator], assets)

    if (purrr::is_empty(low_level_assets)) {
        top_level_assets
    } else {
        join_list(
            top_level_assets,
            purrr::reduce(low_level_assets, join_list)
        )
    }
}

join_list <- function(x, y) {
    if (purrr::is_empty(x)) return(list())
    if (purrr::is_empty(y)) return(x)
    list(head = c(x$head, y$head), body = c(y$body, x$body))  # order is strict
}

# Assets are moved to the top, R scripts are moved to the bottom
sort_list <- function(x, indicator, names) {
    setNames(list(x[indicator], x[!indicator]), names)
}


# Takes string input:    "#! load_script('https://abc/def.js')"
# Returns string output: "https://abc/def.js"
extract_src <- function(x) {
    args <- parse0(substring(x, 3))[[2]]
    if (args[[1]] %in% c('src', 'sketch::src')) {
        src(args[[2]])
    } else {
        args
    }
    # Potential refactoring in the future:
    # - Handle optional arguments
    # - `convert_src` may need to be changed accordingly
    #
    # ast <- as.list(parse0(substring(x, 3)))
    # ret <- if (is.null(ast$src)) ast[[2]] else ast$src
    #
    # # Post-processing
    # if (!is.null(ast$cache)) {
    #     attr(ret, "cache") <- ast$cache
    # }
    # ret
}


#' Load JavaScript / CSS / R Sketch Script / CSV file
#' @param x A character string; the link / path to the JS / CSS / R script / CSV file.
#' @param renderer function; the function to render the shiny tag object.
#' Use `htmltools::doRenderTags` for RMD, and `identity` for `html_template`.
#' @keywords internal
convert_src <- function(x) {
    # JS, CSS: local or web,  R, CSV: local only.
    # web links are kept as-is; local are turned into URI (except CSS is kept in-line).
    script  <- htmltools::tags$script
    link    <- htmltools::tags$link
    style   <- htmltools::tags$style
    dataURI <- base64enc::dataURI

    if (is_web_link(x)) {
        if (is_javascript(x)) {
            script(src = x)

        } else if (is_css(x)) {
            link(href = x, rel = "stylesheet")

        } else if (is_font(x)) {
            link(href = x, rel = "preload")

        } else {
            stop("Web support only works for JavaScript, CSS and Web-fonts links.")
        }
    } else {
        if (is_javascript(x)) {
            URI <- dataURI(file = x)
            script(src = URI)

        } else if (is_css(x)) {
            content <- paste(readLines(x), collapse = "\n")
            style(content, rel = "stylesheet")

        } else if (is_r_script(x)) {
            index_js <- compile_r(x, tempfile())
            URI <- dataURI(file = index_js)
            script(src = URI)

        } else if (is_csv(x) || is_json(x)) {
            index_js <- compile_data(x, tempfile())
            URI <- dataURI(file = index_js)
            script(src = URI)

        } else {
            stop("Script must be one of JavaScript, CSS, RScript, JSON and CSV.")
        }
    }
}


#====================================================================
# Predicate functions
is_src_line <- function(x) substr(x, 1, 2) == "#!"


is_web_link <- function(x) {
    has_prefix(x, "http://") || has_prefix(x, "https://")
}
is_local <- function(x) !is_web_link(x)


is_javascript <- function(x) extname(x) == "js"
is_r_script   <- function(x) extname(x) == "r"
is_css        <- function(x) extname(x) == "css"
is_json       <- function(x) extname(x) == "json"
is_csv        <- function(x) extname(x) == "csv"
is_font       <- function(x) extname(x) %in% c("woff", "ttf", "eot", "otf")


# Check if input 'x' has the prefix 'y'
has_prefix <- function(x, y) substr(x, 1, nchar(y)) == y
extname <- function(x) {
    filename <- basename(x)
    tolower(tail(unlist(strsplit(filename, "[.]")), 1))
}
