html_template <- function(id = "new_sketch", ...) {
    utils <- base64enc::dataURI(file = system.file("assets/utils.js", "sketch"))
    htmltools::tagList(
        htmltools::tags$html(
            htmltools::tags$head(
                htmltools::tags$script(src = src("math")),
                htmltools::tags$script(src = src("dataframe")),
                ...,
                htmltools::tags$script(utils)
            ),
            htmltools::tags$body(
                htmltools::tags$div(id = id),
                htmltools::tags$script(src = "./index.js")
            )
        )
    )
}


#' Get the source link of a JavaScript library
#' @param x A character string; name of the JavaScript library
#' @export
src <- function(x) {
    switch(x,
        "dataframe" = "https://gmousse.github.io/dataframe-js/dist/dataframe.min.js",
        "math" = "https://cdnjs.cloudflare.com/ajax/libs/mathjs/6.2.2/math.min.js",
        "p5" = "https://cdnjs.cloudflare.com/ajax/libs/p5.js/0.9.0/p5.js",
        "plotly" = "https://cdn.plot.ly/plotly-latest.min.js"
    )
}