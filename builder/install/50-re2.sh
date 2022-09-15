#!/usr/bin/env bash

set -e

cd third_party/re2

cp LICENSE "${LICENSE_DIR}/re2-${RE2_VERSION}"

make ${NPROCS:+-j ${NPROCS}}
make ${NPROCS:+-j ${NPROCS}} shared-install
