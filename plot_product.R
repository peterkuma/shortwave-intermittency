#!/usr/bin/env Rscript
#
# plot_product.R
#

library(rjson)

program.name <- 'plot_product.R'

usage <- function() {
	write(sprintf('Usage: %s <product> <dir>', program.name), stderr())
}

plot.dataset <- function(mu0, ds, filename, differential=FALSE, log.scale=FALSE) {
	nlevels <- length(ds$data[[1]])
	N <- length(mu0$data)

	cat(sprintf("%s\n", filename))
	cairo_pdf(filename, width=12, height=12)

	if (differential) {
		X <- lapply(1:nlevels, function(lev) {
			mu0$data[2:N]
		})

		Y <- lapply(1:nlevels, function(lev) {
			diff(sapply(ds$data, function(x) { x[lev] }))/diff(mu0$data)
		})
	} else {
		X <- lapply(1:nlevels, function(lev) {
			mu0$data
		})

		Y <- lapply(1:nlevels, function(lev) {
			sapply(ds$data, function(x) { x[lev] })
		})
	}

	xmax <- max(sapply(1:nlevels, function(lev) { max(X[[lev]]) }))
	xmin <- min(sapply(1:nlevels, function(lev) { min(X[[lev]]) }))
	ymax <- max(sapply(1:nlevels, function(lev) { max(Y[[lev]]) }))
	ymin <- min(sapply(1:nlevels, function(lev) { min(Y[[lev]]) }))

	if (xmin == xmax) {
		xmin <- xmin - 1
		xmax <- xmax + 1
	}

	if (ymin == ymax) {
		ymin <- ymin - 1
		ymax <- ymax + 1
	}

	plot(
		NULL,
		type='n',
		xlim=c(xmin, xmax),
		ylim=c(ymin, ymax),
		xlab=sprintf('%s (%s)', mu0$desc, mu0$units),
		ylab=sprintf('%s (%s)', ds$desc, ds$units),
		log=ifelse(log.scale, 'xy', '')
	)

	for (lev in seq(1, nlevels, 1)) {
		x <- X[[lev]]
		y <- Y[[lev]]
		lines(x, y, lw=0.4)
		#points(x, y, pch=20, cex=0.5)
		text(max(x), y[which.max(x)], lev-1, cex=0.7)
		text(min(x), y[which.min(x)], lev-1, cex=0.7)
		text(x[which.max(y)], max(y), lev-1, cex=0.7)
		text(x[which.min(y)], min(y), lev-1, cex=0.7)
	}

	dev.off()
}

args <- commandArgs(trailingOnly=TRUE)
if (length(args) != 2) {
	usage()
	quit(status=1)
}

product.filename <- args[1]
dirname <- args[2]

product <- fromJSON(file=product.filename)

for (name in names(product)) {
	product[[name]]$name <- name
}

N <- length(product$mu0$data)

# a_H <- 1/0.001324
# mu0 <- product$mu0$data
# mu0_dash <- 1/(((a_H*mu0)**2 + 2*a_H + 1)**(1/2) - a_H*mu0)

system(sprintf('mkdir -p %s', shQuote(dirname)))

for (name in names(product)) {
	#if (name == 'mu0' || name == 'mu0_dash') {
	if (name == 'mu0_dash') {
		next
	}
	ds <- product[[name]]
	plot.dataset(
		product$mu0_dash,
		ds,
		sprintf('%s/%s.pdf', dirname, name)
	)
	if (all(unlist(ds$data) > 0)) {
		plot.dataset(
			product$mu0_dash,
			ds,
			sprintf('%s/%s_log.pdf', dirname, name),
			log.scale=TRUE
		)
	} else {
		write(sprintf('%s: "%s" contains negative values, not plotting log plot',
			program.name, name), stderr())
	}
	plot.dataset(
		product$mu0_dash,
		ds,
		sprintf('%s/%s_diff.pdf', dirname, name),
		differential=TRUE
	)
}

# plot.dataset(
# 	product$mu0_dash,
# 	list(
# 		name='optical_depth',
# 		desc='Optical depth (1)',
# 		data=lapply(1:N, function(n) {
# 			c(product$optical_depth_downward$data[[n]], product$optical_depth_upward$data[[n]])
# 		})
# 	),
# 	sprintf('%s/optical_depth.pdf', dirname)
# )

# plot.dataset(
# 	product$mu0_dash,
# 	list(
# 		name='optical_thickness',
# 		desc='Optical thickness (1)',
# 		data=lapply(1:N, function(n) {
# 			c(product$optical_thickness_downward$data[[n]], product$optical_thickness_upward$data[[n]])
# 		})
# 	),
# 	sprintf('%s/optical_thickness.pdf', dirname)
# )
