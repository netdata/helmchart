#!/usr/bin/env python3

import sys
import pathlib
from argparse import ArgumentParser, RawDescriptionHelpFormatter

import semver

from ruamel.yaml import YAML


yaml = YAML(typ='rt')
yaml.indent(mapping=2, sequence=4, offset=2)
PREFIX = pathlib.PurePath('charts', 'netdata')


def _parse_command_line():
    """Defines arguments for the program and parses the given command line"""
    parser = ArgumentParser(
        formatter_class=RawDescriptionHelpFormatter,
        description=("""\
             Specify  arguments as listed below
             Examples:
             --------------------------------
                python update_version.py get_chart_version
                python update_version.py set_chart_version
                python update_version.py get_app_version
                python update_version.py set_app_version --version v1.31.0
    """))

    parser.add_argument('action',
                        choices=['get_chart_version', 'set_chart_version',
                                 'get_app_version', 'set_app_version'])
    parser.add_argument(
                '--version',
                required=False,
                type=str,
                nargs='?',
                help='Version to set.')
    return parser.parse_args()


class Versioning:
    """ Getting current Chart and App versions and bumping to new ones """
    def __init__(self, chart_data, action, version=None):
        self.action = action
        self.version = version
        self.chart_data = chart_data

    def run(self):
        getattr(self, self.action)()

    def get_chart_version(self):
        print(self.chart_data['version'])

    def set_chart_version(self):
        old_chart_data = self.chart_data['version']
        new_chart_version = semver.VersionInfo.parse(old_chart_data).next_version(part='patch')

        FileHandler.write_readme(old_chart_data, new_chart_version)
        self.chart_data['version'] = str(new_chart_version)
        FileHandler.write_chart(self.chart_data)

    def get_app_version(self):
        print(self.chart_data['appVersion'])

    def set_app_version(self):
        new_app_version = self.version
        FileHandler.write_readme(self.chart_data['appVersion'],
                                 new_app_version)
        self.chart_data['appVersion'] = new_app_version
        FileHandler.write_chart(self.chart_data)


class FileHandler(object):
    """ Handling the Chart and app versions in Chart.yaml and README.md files """
    @staticmethod
    def load_chart_file():
        with open(PREFIX.joinpath('Chart.yaml'), 'r', encoding='UTF-8') as chart:
            chart_data = yaml.load(chart)
        return chart_data

    @staticmethod
    def write_chart(chart_data):
        with open(PREFIX.joinpath('Chart.yaml'), 'w', encoding='UTF-8') as chart:
            yaml.dump(chart_data, chart)

    @staticmethod
    def write_readme(old_version, new_version):
        with open(PREFIX.joinpath('README.md'), 'r+', encoding='UTF-8') as readme:
            data = readme.read()
            data = data.replace(str(old_version), str(new_version), 2)
            readme.seek(0)
            readme.write(data)
            readme.truncate()


def main():
    args = _parse_command_line()
    chart_data = FileHandler.load_chart_file()
    if args.action == 'set_app_version' and not args.version:
        print("You must specify an app version for the 'set_app_version' command")
        sys.exit(1)
    Versioning(chart_data, args.action, args.version).run()


if __name__ == "__main__":
    main()
