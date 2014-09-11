#!/usr/bin/env python
#
# run.py
#
# References:
#
#     * Masek J. 2013. Single interval showtwave radiation scheme with
#       parametrized optical saturation and spectral overlaps.
#

import sys
from tempfile import NamedTemporaryFile
import subprocess
import numpy as np
from StringIO import StringIO
import json
import jinja2


# Constants.
a_H = 1/0.001324  # a/H (Masek, 2013).


def usage():
	print >> sys.stderr, 'Usage: %s <namelist> <input>' % sys.argv[0]


class JSONEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, np.ndarray):
            return obj.tolist()
        return json.JSONEncoder.default(self, obj)


def call_acra2(nml):
	#with open('tmp', 'wb') as fp:
	with NamedTemporaryFile() as fp:
		fp.write(nml)
		fp.flush()
		p = subprocess.Popen(['./acra2', fp.name], stdout=subprocess.PIPE)
		output = p.communicate()[0]
		if p.returncode != 0:
			raise RuntimeError('./acra2 failed with code %d' % p.returncode)
		return parse_acra2(output)


def parse_acra2(output):
	s = ''
	for line in output.split('\n'):
		if line.startswith('#'):
			continue
		s += line + '\n'
	sio = StringIO(s)
	return np.loadtxt(sio)


if __name__ == '__main__':
	program_name = sys.argv[0]

	if len(sys.argv) != 3:
		usage()
		sys.exit(1)

	nml_filename = sys.argv[1]
	input_filename = sys.argv[2]

	# Load namelist.
	try:
		with open(nml_filename) as fp:
			nml_template = fp.read()
	except IOError as err:
		print >> sys.stderr, '%s: %s' % (err.filename, err.strerror)
		sys.exit(1)

	# Load input.
	try:
		with open(input_filename) as fp:
			input = json.load(fp)
	except IOError as err:
		print >> sys.stderr, '%s: %s' % (err.filename, err.strerror)
		sys.exit(1)

	mu0 = np.array(input['mu0'])
	mu0_dash = 1.0/(((a_H*mu0)**2.0 + 2.0*a_H + 1.0)**0.5 - a_H*mu0)
	N = len(mu0)

	#
	# Run SCM for each value of mu0.
	#
	out = []
	for n in range(N):
		template = jinja2.Template(nml_template)

		# Fill in namespace template.
		context = {
			'ZMU0': mu0[n],
			'LFORCEEO': False,
			'ZDEOSI': None,
			'ZUEOSI': None,
		}
		if 'optical_thickness_downward' in input and \
		   'optical_thickness_upward' in input:
			context['LFORCEEO'] = True
			context['ZDEOSI'] = np.array(input['optical_thickness_downward'][n])
			context['ZUEOSI'] = \
				np.array(input['optical_thickness_upward'][n])/(2.0*mu0_dash[n])
		nml = template.render(context)
		
		# Run SCM.
		try:
			out.append(call_acra2(nml))
		except RuntimeError as err:
			print >> sys.stderr, '%s: %s' % (program_name, err)
			sys.exit(1)

	pressure = [
		out[n][:,0]
		for n in range(N)
	]

	heating_rate_shortwave = [
		out[n][:,1]
		for n in range(N)
	]

	heating_rate_longwave = [
		out[n][:,2]
		for n in range(N)
	]

	optical_thickness_downward = [
		out[n][:,3]
		for n in range(N)
	]

	optical_thickness_upward = [
		out[n][:,4]*(2.0*mu0_dash[n])
		for n in range(N)
	]

	optical_depth_downward = [
		np.cumsum(optical_thickness_downward[n])
		for n in range(N)
	]

	optical_depth_upward = [
		sum(optical_thickness_downward[n]) + \
		np.cumsum(optical_thickness_upward[n])
		for n in range(N)	
	]

	optical_thickness = [np.hstack((
			optical_thickness_downward[n],
			optical_thickness_upward[n]
		))
		for n in range(N)
	]

	optical_depth = [np.hstack((
			optical_depth_downward[n],
			optical_depth_upward[n]
		))
		for n in range(N)
	]

	print json.dumps({
		'mu0': {
			'data': mu0,
			'desc': 'Cosine of zenithal angle',
			'units': '1',
		},
		'mu0_dash': {
			'data': mu0_dash,
			'desc': 'Modified cosine of zenithal angle',
			'units': '1',
		},
		'pressure': {
			'data': pressure,
			'desc': 'Pressure',
			'units': 'Pa'
		},
		'heating_rate_shortwave': {
			'data': heating_rate_shortwave,
			'desc': 'Heating rate shortwave',
			'units': 'K/day',
		},
		'heating_rate_longwave': {
			'data': heating_rate_longwave,
			'desc': 'Heating rate longwave',
			'units': 'K/day',
		},
		'optical_thickness_downward': {
			'data': optical_thickness_downward,
			'desc': 'Optical thickness downward',
			'units': '1',
		},
		'optical_thickness_upward': {
			'data': optical_thickness_upward,
			'desc': 'Optical thickness upward',
			'units': '1',
		},
		'optical_depth_downward': {
			'data': optical_depth_downward,
			'desc': 'Optical depth downward',
			'units': '1',
		},
		'optical_depth_upward': {
			'data': optical_depth_upward,
			'desc': 'Optical depth upward',
			'units': '1',
		},
		'optical_depth': {
			'data': optical_depth,
			'desc': 'Optical depth',
			'units': '1',
		},
		'optical_thickness': {
			'data': optical_thickness,
			'desc': 'Optical thickness',
			'units': '1',
		},
	}, cls=JSONEncoder, indent=True)
