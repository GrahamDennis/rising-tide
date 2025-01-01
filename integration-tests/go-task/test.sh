#!/bin/bash

set -eu -o pipefail

# taskfile.yml must exist
test -h taskfile.yml