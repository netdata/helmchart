#!/usr/bin/env bash

set -euo pipefail

helm-docs -t "./templates/netdata-README.md.gotmpl" -g "charts/netdata" --ignore-non-descriptions --sort-values-order file
