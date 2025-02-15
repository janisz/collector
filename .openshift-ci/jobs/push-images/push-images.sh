#!/usr/bin/env bash
set -eo pipefail

CI_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/../.. && pwd)"
# shellcheck source=SCRIPTDIR/../../scripts/lib.sh
source "${CI_ROOT}/scripts/lib.sh"

export PROJECT_DIR=/go/src/github.com/stackrox/collector

push_images_to_repos() {
    local -n local_image_repos=$1
    local -n local_tags=$2
    local image_name=$3
    local osci_image=$4

    for repo in "${local_image_repos[@]}"; do
        registry_rw_login "$repo"

        for tag in "${local_tags[@]}"; do
            image="${repo}/${image_name}:${tag}"
            echo "Pushing image ${image}"
            oc image mirror "${osci_image}" "${image}"
        done
    done
}

push_builder_image() {

    BRANCH="$(get_branch)"
    tags=("$collector_version")

    if [[ "$BRANCH" == "master" ]]; then
        # shellcheck disable=SC2034
        tags+=("cache")
    fi

    oc registry login

    push_images_to_repos image_repos tags collector-builder "${COLLECTOR_BUILDER}"
}

push_images() {
    oc registry login

    # shellcheck disable=SC2034
    full_tags=(
        "${collector_version}"
        "${collector_version}-latest"
    )
    push_images_to_repos image_repos full_tags collector "${COLLECTOR_FULL}"

    if ((CPAAS_TEST)); then
        # All done
        return 0
    fi

    # shellcheck disable=SC2034
    base_tags=(
        "${collector_version}-slim"
        "${collector_version}-base"
    )
    push_images_to_repos image_repos base_tags collector "${COLLECTOR_SLIM}"
}

cd "$PROJECT_DIR"

collector_version="$(make tag)"
CPAAS_TEST=${CPAAS_TEST:-0}

if ((CPAAS_TEST)); then
    collector_version="cpaas-${collector_version}"
fi

export PUBLIC_REPO=quay.io/stackrox-io
export QUAY_REPO=quay.io/rhacs-eng

import_creds

# Note that shellcheck reports unused variable when arrays are passed as reference.
# See https://github.com/koalaman/shellcheck/issues/1957
# shellcheck disable=SC2034
image_repos=(
    "${QUAY_REPO}"
    "${PUBLIC_REPO}"
)

push_images

if ((CPAAS_TEST)); then
    # All done
    exit 0
fi

push_builder_image
