#!/usr/bin/env python3

import pathlib
import sys

import semver

from ruamel.yaml import YAML

PREFIX = pathlib.PurePath('charts', 'netdata')

NEW_APP_VERSION = sys.argv[1]

yaml = YAML(typ='rt')
yaml.indent(mapping=2, sequence=4, offset=2)

with open(PREFIX.joinpath('Chart.yaml'), 'r') as chart:
    chart_data = yaml.load(chart)

old_chart_version = semver.VersionInfo.parse(chart_data['version'])
new_chart_version = old_chart_version.next_version(part='patch')

OLD_APP_VERSION = chart_data['appVersion']

chart_data['version'] = str(new_chart_version)
chart_data['appVersion'] = NEW_APP_VERSION

with open(PREFIX.joinpath('Chart.yaml'), 'w') as chart:
    yaml.dump(chart_data, chart)

with open(PREFIX.joinpath('README.md'), 'r+') as readme:
    data = readme.read()
    data = data.replace(str(old_chart_version), str(new_chart_version))
    data = data.replace(OLD_APP_VERSION, NEW_APP_VERSION)
    readme.seek(0)
    readme.write(data)
