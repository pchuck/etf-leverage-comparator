#! /usr/bin/env Rscript
##
## wrapper around knitr for rendering markdown to html
## NOTE: knitr rendering requires a 'pandoc' installation
##
library(knitr)

args <- commandArgs(trailingOnly=TRUE)
if(length(args) < 1) {
    print("usage: knit file")
    print("  e.g. knit example")
    quit()
}

fileName <- args[1]
rmd <- paste(fileName, ".Rmd", sep = "")
rhtml <- paste(fileName, ".html", sep = "")

## to write md to file..
## knit(rmd)

## to write html to file..
## rmarkdown::render(rmd, "html_document")

## to render and send to browser..
knit2html(rmd)
browseURL(rhtml)

