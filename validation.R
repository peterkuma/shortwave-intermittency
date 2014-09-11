#!/usr/bin/Rscript
#
# validation.R
#
# Perform comparison of a product with respect to reference.
#

library(rjson)

program.name <- 'validation.R'

usage <- function() {
	write(sprintf('Usage: %s <product> <reference>', program.name), stderr())
}

args <- commandArgs(trailingOnly=TRUE)
if (length(args) != 2) {
	usage()
	quit(status=1)
}

product.filename <- args[1]
reference.filename <- args[2]

product <- fromJSON(file=product.filename)
reference <- fromJSON(file=reference.filename)

N <- length(product$mu0$data)

output <- list()
output$mu0_dash <- product$mu0_dash
for (name in names(product)) {
	if (!(name %in% names(reference))) {
		next
	}

	if (name == 'mu0_dash') {
		next
	}

	name2 <- sprintf('%s_difference', name)
	output[[name2]] <- product[[name]]
	output[[name2]]$desc <- sprintf('%s difference', output[[name2]]$desc)
	output[[name2]]$data <- lapply(1:N, function(n) {
		product[[name]]$data[[n]] - reference[[name]]$data[[n]]
	})

	name2 <- sprintf('%s_relative_difference', name)
	output[[name2]] <- product[[name]]
	output[[name2]]$desc <- sprintf('%s relative difference', output[[name2]]$desc)
	output[[name2]]$units <- '%'
	output[[name2]]$data <- lapply(1:N, function(n) {
		100*(product[[name]]$data[[n]] - reference[[name]]$data[[n]])/reference[[name]]$data[[n]]
	})
	# Replace NaN with 0.
	output[[name2]]$data <- lapply(1:N, function(n) {
		ifelse(is.nan(output[[name2]]$data[[n]]), 0, output[[name2]]$data[[n]])
	})
}

cat(toJSON(output))
