Solar Intermittence
===================

This is a set of scripts for testing solar intermittence in the ACRANEB2
radiative transfer scheme using SCM (Single Cell Model).

Getting Started
---------------

### Requirements

* [Python](https://www.python.org/) 2.6 or newer
* [R](http://www.r-project.org/)
* [numpy](http://www.numpy.org/)
* [jinja2](http://jinja.pocoo.org/)
* [rjson](http://cran.r-project.org/web/packages/rjson/index.html)

### Installation

1. Install requirements (Ubuntu/Debian):

	apt-get install python python-numpy r-base

2. Install python packages:

	pip install --user jinja2

2. Install R packages:

	echo "install.packages('rjson', repos='http://cran.rstudio.com/')" | R --no-save

Create a symbolic link to acra2 (SCM model executable) in the local directory:

	ln -s /path/to/scm/bin/acra2

Overview
--------

### input.py

Prepare input for `run.py` (see below). Calculates zenithal angles
according to chosen intermittence constants specified inside the script.

#### Usage

	./input.py <start> <stop> <interval>

#### Arguments

* **start**

	Starting angle in degree.

* **stop**

	Stop angle in degrees.

* **interval**

	Intermittence interval in degrees.

### run.py

Run the SCM model multiple times for different values of zenithal angle,
optionally supplying given optical thicknesses to the model.

#### Usage

	./run.py <namelist> <input>

#### Arguments

* **namelist**

	A template of Fortran namelist for the SCM model. The template
	is formatted using [jinja2](http://jinja.pocoo.org/), supplied with
	variables:

		* `mu0` – zenithal angles
		* `optical_thickness_downward`
			– downward optical thickness (if present in *input*)
		* `optical_thickness_upward`
			– upward optical thickness (if present in *input*)

* **input**

	Input specification. Example:

		{
			"mu0": [0, 0.5, 1]
			"optical_thickness_downward": [
				[...],
				[...]
			],
			"optical_thickness_upward": [
				[...],
				[...]
			]
		}

	`mu0` specifies zenithal angles at which to run the model.
	`optical_thickness_downward` and `optical_thickness_upward` are optional
	and specify given optical depths with which the model is forced to run.

### plot_product.R

Plot datasets from a product (output of `run.py`).
The script produces a PDF plot for each dataset in the product.

#### Usage

	./plot_product.R <product> <dir>


#### Arguments

* **product**

	Product containing datasets as output by `run.py`.

* **dir**

	Output directory.

### interpolate.R

Perform linear interpolation of optical depths. Outputs JSON suitable 
as input for `run.py`.

#### Usage

	./interpolate.R <product> <input>

#### Arguments

* **product**

Product file as output by `run.py`. Optical depths from the product
are used as interpolation points.

* **input**

Input file as in `run.py`. Determines points where to interpolate.

### validation.R

Perform comparison of a product with respect to reference.

Outputs a product containing datasets which are differences between the
corresponding datasets in *product* and *reference*.

#### Usage

	./validation.R <product> <reference>

#### Arguments

* **product**

	Product to be validated.

* **reference**

	Product to be used as a reference.

Example
-------

	# Prepare input for run.py:
	# Angles from 0 to 90 deg by 15-deg steps (coarse).
	./input.py 0 90 15 > input_15deg.json

	# Angles from 0 to 90 deg by 1-deg steps (dense).
	./input.py 0 90 1 > input_1deg.json

	# Run SCM with the coarse input.
	./run.py nam_clear_s240.template input_15deg.json > product.json

	# Run SCM with the dense input as reference.
	./run.py nam_clear_s240.template input_1deg.json > product_ref.json

	# Plot product to directory product.
	./plot_product.R product.json product
	./plot_product.R product_ref.json product_ref

	# Perform interpolation of optical depths at 1-degree intervals.
	./interpolate.R product.json input_1deg.json > input_linear_interp.json

	# Run SCM with the interpolated optical depths.
	./run.py nam_clear_s240.template input_linear_interp.json > product_linear_interp.json

	# Plot product to directory product_linear_interp.
	./plot_product.R product_linear_interp.json product_linear_interp

	# Compare interpolation to reference.
	./validation.R product_linear_interp.json product_ref.json > validation.json

	# Plot comparison.
	./plot_product.R validation.json validation
