#!/usr/bin/env python
#
# input.py
#
# Prepare input for run.py.
#
# Usage: ./input.py > input.json
#

import sys
import numpy as np
import json


# Constants.
# interval = 15  # Intermittence interval in degrees.
# start = 0  # Start zenithal angle in degrees.
# stop = 90  # Stop zenithal angle in degrees.


def usage():
	print >> sys.stderr, 'Usage: %s <start> <stop> <interval>' % sys.argv[0]


if __name__ == '__main__':
	program_name = sys.argv[0]

	if len(sys.argv) != 4:
		usage()
		sys.exit(1)

	try:
		start = float(sys.argv[1])
		stop = float(sys.argv[2])
		interval = float(sys.argv[3])
	except ValueError as err:
		print >> sys.stderr, '%s: Invalid argument' % program_name
		usage()
		sys.exit(1)

	mu0 = [
		np.cos(theta/180.0*np.pi)
		for theta in np.arange(start, stop + interval, interval)
	]

	print json.dumps({
		"mu0": mu0
	})
