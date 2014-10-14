#!/usr/bin/env Rscript
#
# interpolate.R
#
# Interpolate optical depths.
#

library(rjson)

program.name <- 'interpolate.R'
a_H <- 1/0.001324 # a/H (Masek, 2013)

usage <- function() {
	write(sprintf('Usage: %s <product> <input>', program.name), stderr())
}

modified.cos.zenithal.angle <- function(mu0) {
	1/(((a_H*mu0)**2 + 2*a_H + 1)**(1/2) - a_H*mu0)
}

args <- commandArgs(trailingOnly=TRUE)
if (length(args) != 2) {
	usage()
	quit(status=1)
}

product.filename <- args[1]
input.filename <- args[2]

product <- fromJSON(file=product.filename)
input <- fromJSON(file=input.filename)

N <- length(input$mu0) # Number of zenithal angles.
nlevels <- length(product$optical_thickness_downward$data[[1]]) # Number of levels.
mu0.dash <- modified.cos.zenithal.angle(input$mu0)

optical.thickness.downward <- lapply(1:nlevels, function(lev) {
	exp(approx(
		log(product$mu0_dash$data),
		log(sapply(product$optical_thickness_downward$data, function(x) { x[lev] })),
		log(mu0.dash)
	)$y)
})

optical.thickness.upward <- lapply(1:nlevels, function(lev) {
	if (lev == 1) {
		return(rep(0, N))
	}
	exp(approx(
		log(product$mu0_dash$data),
		log(sapply(product$optical_thickness_upward$data, function(x) { x[lev] })),
		log(mu0.dash)
	)$y)
})

cat(toJSON(list(
	mu0=input$mu0,
	optical_thickness_downward=lapply(1:N, function(n) {
		sapply(1:nlevels, function(lev) {
			optical.thickness.downward[[lev]][n]
		})
	}),
	optical_thickness_upward=lapply(1:N, function(n) {
		sapply(1:nlevels, function(lev) {
			optical.thickness.upward[[lev]][n]
		})
	})
)))
